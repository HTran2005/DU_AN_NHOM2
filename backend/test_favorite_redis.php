<?php
/**
 * ===============================================
 * TRANG TEST: KẾT NỐI REDIS LƯU / ĐỌC TOUR YÊU THÍCH
 * ===============================================
 * Mục đích: kiểm tra trực tiếp việc lưu trữ (SADD/SREM) và đồng bộ
 * (Redis -> Database) danh sách tour yêu thích của người dùng.
 *
 * Cách dùng (chạy trên App Service trực tiếp):
 *   https://<webapp>/backend/test_favorite_redis.php
 *
 * Tham số (nộp qua form hoặc query string):
 *   user_id : id người dùng cần kiểm tra (mặc định: người đang đăng nhập)
 *   tour_id : id tour dùng cho thao tác Thêm/Xoá
 *   combo_id: id combo dùng cho thao tác Thêm/Xoá (tuỳ chọn, tour là chính)
 *   action  : add | remove | read | sync | clear
 */

ini_set('display_errors', 1);
ini_set('error_reporting', E_ALL);

// Nạp .env nếu có (local); trên App Service biến môi trường được đặt natively
// nên trang vẫn hoạt động ngay cả khi không có vendor/autoload.php.
if (file_exists(__DIR__ . '/vendor/autoload.php')) {
    require_once __DIR__ . '/vendor/autoload.php';
    if (file_exists(__DIR__ . '/.env') && class_exists('\Dotenv\Dotenv')) {
        $dotenv = \Dotenv\Dotenv::createImmutable(__DIR__);
        $dotenv->load();
    }
}

// Tắt auto-connect DB trong config.php: trang test tự kết nối để vẽ HTML đầy đủ
// ngay cả khi DB đang lỗi (chỉ phần "Database" hiển thị lỗi).
if (!defined('APP_SKIP_DB_CONNECT')) {
    define('APP_SKIP_DB_CONNECT', true);
}
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/RedisClient.php';

// =====================================================
// 1. KẾT NỐI DATABASE (thu thập lỗi để hiển thị, không chết trang)
// =====================================================
global $conn;
$conn     = null;
$dbOk     = false;
$dbError  = '';
if (DB_HOST !== '' && DB_USER !== '') {
    try {
        $conn = mysqli_init();
        mysqli_ssl_set($conn, NULL, NULL, NULL, NULL, NULL);
        $conn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 10);
        $ok = @$conn->real_connect(DB_HOST, DB_USER, DB_PASS, DB_NAME, 3306, NULL, MYSQLI_CLIENT_SSL);
        if ($ok && $conn->ping()) {
            $dbOk = true;
            $conn->set_charset(DB_CHARSET);
        } else {
            $dbError = $conn->connect_error ?: 'Không thể kết nối';
            $conn = null;
        }
    } catch (Throwable $e) {
        $dbError = $e->getMessage();
        $conn = null;
    }
} else {
    $dbError = 'DB_HOST/DB_USER chưa được cấu hình (.env / App Settings)';
}

// =====================================================
// 2. KẾT NỐI REDIS + CẤU HÌNH
// =====================================================
$redisCfg = require __DIR__ . '/redis.php';
$rc       = getRedisClientInstance();
$redisOk  = $rc->available();

$favoriteTtl = (int)(($_ENV['REDIS_FAVORITE_TTL'] ?? getenv('REDIS_FAVORITE_TTL')) ?: 600);

function esc($v) {
    return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8');
}

// =====================================================
// 3. THAM SỐ & HÀNH ĐỘNG
// =====================================================
if (session_status() === PHP_SESSION_NONE) {
    @session_start();
}
$userId   = intval($_GET['user_id'] ?? ($_POST['user_id'] ?? 0));
$tourId   = intval($_GET['tour_id'] ?? ($_POST['tour_id'] ?? 0));
$comboId  = intval($_GET['combo_id'] ?? ($_POST['combo_id'] ?? 0));
$action   = $_POST['action'] ?? ($_GET['action'] ?? 'read');

if ($userId <= 0 && isset($_SESSION['user_id'])) {
    $userId = intval($_SESSION['user_id']);
}
if ($userId < 0) $userId = 0;

$key      = 'tripto:favorite:user:' . $userId;
$dirtyKey = $key . ':dirty';

$messages = [];

/**
 * Đọc danh sách tour theo id từ Database (để hiển thị tên + giá).
 */
function fetchTourNames(array $ids) {
    global $conn;
    $map = [];
    if (!$conn || empty($ids)) return $map;
    $ids = array_values(array_unique(array_map('intval', $ids)));
    if (empty($ids)) return $map;
    $in = implode(',', array_fill(0, count($ids), '?'));
    $stmt = $conn->prepare("SELECT id, ten, gia, url_anh_chinh FROM tour WHERE id IN ($in)");
    if ($stmt) {
        $types = str_repeat('i', count($ids));
        $stmt->bind_param($types, ...$ids);
        $stmt->execute();
        $res = $stmt->get_result();
        while ($row = $res->fetch_assoc()) {
            $map[intval($row['id'])] = $row;
        }
        $stmt->close();
    }
    return $map;
}

/**
 * Đọc danh sách yêu thích từ Database của user.
 */
function dbFavorites($userId) {
    global $conn;
    if (!$conn) return null;
    $rows = [];
    $stmt = $conn->prepare(
        "SELECT id, id_tour, id_goi_combo, id_nhom, ngay_them
         FROM yeu_thich WHERE id_nguoi_dung = ? ORDER BY ngay_them DESC"
    );
    if ($stmt) {
        $stmt->bind_param('i', intval($userId));
        $stmt->execute();
        $res = $stmt->get_result();
        while ($row = $res->fetch_assoc()) $rows[] = $row;
        $stmt->close();
    }
    return $rows;
}

/**
 * Đồng bộ Redis -> Database: chèn những item có trong Redis mà DB chưa có,
 * xoá những row DB không còn trong Redis. Trả về ['added', 'removed'].
 */
function syncRedisToDb($userId, $rc) {
    global $conn;
    if (!$conn) return ['error' => 'Database không kết nối được.'];
    $key = 'tripto:favorite:user:' . intval($userId);

    $members = $rc->smembers($key);
    $redisTours  = [];
    $redisCombos = [];
    foreach ((array)$members as $m) {
        if (preg_match('/^tour:(\d+)$/', trim($m), $mm)) {
            $redisTours[] = intval($mm[1]);
        } elseif (preg_match('/^combo:(\d+)$/', trim($m), $mm)) {
            $redisCombos[] = intval($mm[2]);
        }
    }
    $redisTours  = array_values(array_unique($redisTours));
    $redisCombos = array_values(array_unique($redisCombos));

    $dbRows = dbFavorites(intval($userId)) ?: [];
    $dbTours  = [];
    $dbCombos = [];
    foreach ($dbRows as $r) {
        if (!empty($r['id_tour']))      $dbTours[]  = intval($r['id_tour']);
        if (!empty($r['id_goi_combo'])) $dbCombos[] = intval($r['id_goi_combo']);
    }

    $addTours  = array_diff($redisTours,  $dbTours);
    $delTours  = array_diff($dbTours,     $redisTours);
    $addCombos = array_diff($redisCombos, $dbCombos);
    $delCombos = array_diff($dbCombos,    $redisCombos);

    $added = 0;
    foreach ($addTours as $t) {
        $ins = $conn->prepare("INSERT INTO yeu_thich (id_nguoi_dung, id_tour, ngay_them) VALUES (?, ?, CURRENT_TIMESTAMP)");
        if ($ins) { $ins->bind_param('ii', $userId, $t); if ($ins->execute()) $added++; $ins->close(); }
    }
    foreach ($addCombos as $c) {
        $ins = $conn->prepare("INSERT INTO yeu_thich (id_nguoi_dung, id_goi_combo, ngay_them) VALUES (?, ?, CURRENT_TIMESTAMP)");
        if ($ins) { $ins->bind_param('ii', $userId, $c); if ($ins->execute()) $added++; $ins->close(); }
    }

    $removed = 0;
    if (!empty($delTours) || !empty($delCombos)) {
        $wheres = [];
        $params = [intval($userId)];
        $types  = 'i';
        foreach ($delTours  as $t) { $wheres[] = 'id_tour = ?';      $params[] = $t; $types .= 'i'; }
        foreach ($delCombos as $c) { $wheres[] = 'id_goi_combo = ?'; $params[] = $c; $types .= 'i'; }
        $stmt = $conn->prepare(
            "DELETE FROM yeu_thich WHERE id_nguoi_dung = ? AND (" . implode(' OR ', $wheres) . ")"
        );
        if ($stmt) {
            $stmt->bind_param($types, ...$params);
            if ($stmt->execute()) $removed = $stmt->affected_rows;
            $stmt->close();
        }
    }

    $rc->del($key . ':dirty');
    error_log('[TestFavoriteRedis] DB SYNC user=' . intval($userId)
        . ' added=' . $added . ' removed=' . $removed);
    return ['added' => $added, 'removed' => $removed];
}

// =====================================================
// 4. THỰC HIỆN HÀNH ĐỘNG
// =====================================================
if ($userId > 0) {
    if ($action === 'add') {
        if ($tourId > 0) {
            $res = $rc->sadd($key, 'tour:' . $tourId);
            $rc->expire($key, $favoriteTtl);
            $rc->setex($dirtyKey, $favoriteTtl, (string)time());
            $messages[] = $res !== false && $res !== null
                ? "✅ Đã LƯU tour #{$tourId} vào Redis (SADD → `{$key}`)"
                : "❌ Redis lỗi khi SADD tour #{$tourId}";
        } elseif ($comboId > 0) {
            $res = $rc->sadd($key, 'combo:' . $comboId);
            $rc->expire($key, $favoriteTtl);
            $rc->setex($dirtyKey, $favoriteTtl, (string)time());
            $messages[] = $res !== false && $res !== null
                ? "✅ Đã LƯU combo #{$comboId} vào Redis (SADD → `{$key}`)"
                : "❌ Redis lỗi khi SADD combo #{$comboId}";
        } else {
            $messages[] = '⚠️ Cần nhập <b>tour_id</b> (hoặc combo_id) để thêm vào yêu thích.';
        }
    }

    if ($action === 'remove') {
        if ($tourId > 0) {
            $res = $rc->srem($key, 'tour:' . $tourId);
            $rc->expire($key, $favoriteTtl);
            $rc->setex($dirtyKey, $favoriteTtl, (string)time());
            $messages[] = $res !== false && $res !== null
                ? "✅ Đã XOÁ tour #{$tourId} khỏi Redis (SREM → `{$key}`)"
                : "❌ Redis lỗi khi SREM tour #{$tourId}";
        } elseif ($comboId > 0) {
            $res = $rc->srem($key, 'combo:' . $comboId);
            $rc->expire($key, $favoriteTtl);
            $rc->setex($dirtyKey, $favoriteTtl, (string)time());
            $messages[] = $res !== false && $res !== null
                ? "✅ Đã XOÁ combo #{$comboId} khỏi Redis (SREM → `{$key}`)"
                : "❌ Redis lỗi khi SREM combo #{$comboId}";
        } else {
            $messages[] = '⚠️ Cần nhập <b>tour_id</b> (hoặc combo_id) để xoá khỏi yêu thích.';
        }
    }

    if ($action === 'clear') {
        $rc->del($key);
        $rc->del($dirtyKey);
        $messages[] = "🧹 Đã XOÁ cache Redis `{$key}` (và dirty flag). Dữ liệu DB không đổi.";
    }

    if ($action === 'sync') {
        $result = syncRedisToDb($userId, $rc);
        if (isset($result['error'])) {
            $messages[] = '❌ ' . $result['error'];
        } else {
            $messages[] = "💾 ĐỒNG BỘ Redis → DB: thêm {$result['added']}, xoá {$result['removed']}.";
        }
    }
} elseif ($action !== 'read') {
    $messages[] = '⚠️ Cần nhập <b>user_id</b> để thực hiện thao tác (hoặc đăng nhập trước).';
}

// =====================================================
// 5. DỮ LIỆU HIỂN THỊ
// =====================================================
$redisMembers   = ($userId > 0 && $redisOk) ? ($rc->smembers($key) ?: []) : [];
$redisExist     = ($userId > 0 && $redisOk) ? $rc->exists($key) : false;
$redisTtl       = ($userId > 0 && $redisOk) ? $rc->ttl($key) : null;
$dirtyValue     = ($userId > 0 && $redisOk) ? $rc->get($dirtyKey) : null;
$favoriteKeys   = $redisOk ? ($rc->keys('tripto:favorite:user:*') ?: []) : [];

$parsedTours  = [];
$parsedCombos = [];
foreach ($redisMembers as $m) {
    if (preg_match('/^tour:(\d+)$/', trim($m), $mm))       $parsedTours[]  = intval($mm[1]);
    elseif (preg_match('/^combo:(\d+)$/', trim($m), $mm)) $parsedCombos[] = intval($mm[2]);
}
$tourMap = fetchTourNames($parsedTours);

$dbRows = ($dbOk && $userId > 0) ? (dbFavorites($userId) ?: []) : null;
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Redis - Tour yêu thích</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f4f6fb; margin: 0; padding: 24px; color: #1f2937; }
        .wrap { max-width: 980px; margin: 0 auto; }
        h1 { font-size: 22px; margin: 0 0 4px; }
        .sub { color: #6b7280; font-size: 13px; margin-bottom: 20px; }
        .card { background: #fff; border-radius: 12px; padding: 20px; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0,0,0,.06); }
        .card h2 { font-size: 16px; margin: 0 0 12px; }
        .pill { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 12px; font-weight: 600; margin-left: 8px; vertical-align: middle; }
        .pill.ok { background: #d1fae5; color: #065f46; }
        .pill.bad { background: #fee2e2; color: #991b1b; }
        .pill.warn { background: #fef3c7; color: #92400e; }
        .row { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 12px; align-items: center; }
        label { font-size: 13px; font-weight: 600; margin-right: 4px; }
        input[type=number] { padding: 9px 10px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px; width: 160px; }
        button { padding: 10px 16px; border: none; border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; color: #fff; }
        button:hover { filter: brightness(1.05); }
        .btn-add { background: #0057FF; }
        .btn-remove { background: #dc2626; }
        .btn-read { background: #7c3aed; }
        .btn-sync { background: #10b981; }
        .btn-clear { background: #6b7280; }
        .alert { padding: 12px 14px; border-radius: 8px; margin-bottom: 14px; font-size: 14px; }
        .alert.ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46; }
        .alert.info { background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af; }
        .alert.warn { background: #fffbeb; border: 1px solid #fde68a; color: #92400e; }
        table { width: 100%; border-collapse: collapse; font-size: 13px; }
        th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid #e5e7eb; }
        th { background: #f9fafb; font-weight: 600; }
        code { background: #f3f4f6; padding: 1px 6px; border-radius: 4px; font-size: 12px; }
        .muted { color: #6b7280; font-size: 13px; }
        .kv { display: grid; grid-template-columns: 220px 1fr; gap: 6px 14px; font-size: 14px; }
        .kv b { font-weight: 600; }
        a { color: #0057FF; }
    </style>
</head>
<body>
<div class="wrap">
    <h1>🔍 Test Kết nối Redis — Lưu / Đọc Tour Yêu thích</h1>
    <p class="sub">
        Kiểm tra trực tiếp việc <b>lưu trữ (SADD/SREM)</b> và <b>đồng bộ Redis → Database</b>.
        Dữ liệu gốc trong trang là đọc trực tiếp từ key
        <code>tripto:favorite:user:&lt;user_id&gt;</code>.
    </p>

    <div class="card">
        <h2>Trạng thái kết nối</h2>
        <div class="kv">
            <b>Redis (Azure Cache for Redis)</b>
            <span>
                <?php echo $redisOk ? '<span class="pill ok">KẾT NỐI OK</span>' : '<span class="pill bad">KHÔNG KẾT NỐI ĐƯỢC</span>'; ?>
                <code><?php echo esc($redisCfg['host']); ?>:<?php echo esc($redisCfg['port']); ?></code>
            </span>
            <b>Client</b>
            <span>
                Predis: <?php echo class_exists('\Predis\Client') ? 'có' : 'không'; ?> &nbsp;·&nbsp;
                phpredis: <?php echo class_exists('Redis') ? 'có' : 'không'; ?>
            </span>
            <b>Database (MySQL)</b>
            <span>
                <?php echo $dbOk ? '<span class="pill ok">KẾT NỐI OK</span>' : '<span class="pill bad">LỖI</span>'; ?>
                <?php if (!$dbOk) { ?><span class="muted"><?php echo esc($dbError); ?></span><?php } ?>
            </span>
            <b>Key đang xem</b>
            <span><code><?php echo esc($key); ?></code> (TTL cache: <?php echo $favoriteTtl; ?>s)</span>
        </div>
    </div>

    <div class="card">
        <h2>Thao tác</h2>
        <form method="get" style="margin:0;">
            <div class="row">
                <label for="user_id">User ID</label>
                <input type="number" id="user_id" name="user_id" min="1" value="<?php echo $userId > 0 ? $userId : ''; ?>" placeholder="vd: 3">
                <label for="tour_id">Tour ID</label>
                <input type="number" id="tour_id" name="tour_id" min="1" value="<?php echo $tourId; ?>" placeholder="vd: 1">
                <label for="combo_id">Combo ID</label>
                <input type="number" id="combo_id" name="combo_id" min="1" value="<?php echo $comboId; ?>" placeholder="vd: 2">
            </div>
            <div class="row">
                <button class="btn-add" type="submit" name="action" value="add">➕ Lưu vào Redis</button>
                <button class="btn-remove" type="submit" name="action" value="remove">➖ Xoá khỏi Redis</button>
                <button class="btn-read" type="submit" name="action" value="read">🔄 Đọc từ Redis</button>
                <button class="btn-sync" type="submit" name="action" value="sync">💾 Đồng bộ Redis → DB</button>
                <button class="btn-clear" type="submit" name="action" value="clear">🧹 Xoá cache Redis</button>
            </div>
        </form>
        <p class="muted">💡 Thử flow: nhập <b>User ID</b> + <b>Tour ID</b> → bấm <b>Lưu vào Redis</b> → danh sách bên dưới cập nhật từ Redis → bấm <b>Đồng bộ Redis → DB</b> để xem chênh lệch DB.</p>
    </div>

    <?php if (!empty($messages)): ?>
        <?php foreach ($messages as $msg): ?>
            <div class="alert info"><?php echo $msg; ?></div>
        <?php endforeach; ?>
    <?php endif; ?>

    <div class="card">
        <h2>📦 Redis — Danh sách key yêu thích (đọc SMEMBERS từ Redis)</h2>
        <?php if (!$redisOk): ?>
            <p class="alert warn">Không kết nối được Redis. Kiểm tra <code>REDIS_HOST / REDIS_PORT / REDIS_PASSWORD</code> trong <code>.env</code> hoặc App Settings.</p>
        <?php elseif ($userId <= 0): ?>
            <p class="muted">Nhập User ID để xem dữ liệu.</p>
        <?php elseif (!$redisExist): ?>
            <p class="muted">Key <code><?php echo esc($key); ?></code> chưa tồn tại trong Redis (bấm “Lưu vào Redis” để tạo).</p>
        <?php elseif (empty($redisMembers)): ?>
            <p class="muted">Key tồn tại nhưng SET trống (không có tour/combo nào).</p>
        <?php else: ?>
            <table>
                <tr>
                    <th>Tour / Combo (member trong Redis)</th>
                    <th>ID</th>
                    <th>Tên tour (đọc từ DB)</th>
                    <th>Giá</th>
                </tr>
                <?php foreach ($redisMembers as $m): ?>
                    <?php
                        $p = null;
                        $name = '—';
                        $price = '—';
                        if (preg_match('/^tour:(\d+)$/', trim($m), $mm)) {
                            $p = intval($mm[1]);
                            if (isset($tourMap[$p])) {
                                $name = $tourMap[$p]['ten'];
                                $price = number_format(floatval($tourMap[$p]['gia'])) . ' đ';
                            }
                        }
                    ?>
                    <tr>
                        <td><code><?php echo esc($m); ?></code></td>
                        <td><?php echo $p !== null ? $p : 'combo'; ?></td>
                        <td><?php echo esc($name); ?></td>
                        <td><?php echo esc($price); ?></td>
                    </tr>
                <?php endforeach; ?>
            </table>
            <p class="muted">Tổng: <?php echo count($redisMembers); ?> item trong Redis ·
                TTL còn lại: <?php echo $redisTtl === null ? '?' : $redisTtl . 's'; ?> ·
                Dirty (chưa đồng bộ DB): <?php echo $dirtyValue ? 'có (' . date('H:i:s', (int)$dirtyValue) . ')' : 'không'; ?></p>
        <?php endif; ?>
    </div>

    <div class="card">
        <h2>🗂 Redis — Tất cả key <code>tripto:favorite:user:*</code></h2>
        <?php if (!$redisOk): ?>
            <p class="muted">Không kết nối được Redis.</p>
        <?php elseif (empty($favoriteKeys)): ?>
            <p class="muted">Chưa có key yêu thích nào trên Redis.</p>
        <?php else: ?>
            <table>
                <tr><th>Key</th><th>Số item</th></tr>
                <?php foreach ($favoriteKeys as $fk): ?>
                    <tr>
                        <td><code><?php echo esc($fk); ?></code></td>
                        <td><?php echo (int)($rc->scard($fk) ?: 0); ?></td>
                    </tr>
                <?php endforeach; ?>
            </table>
        <?php endif; ?>
    </div>

    <div class="card">
        <h2>🗄 Database — <code>yeu_thich</code> (so sánh sau Đồng bộ)</h2>
        <?php if (!$dbOk): ?>
            <p class="alert warn">Không kết nối được Database: <?php echo esc($dbError); ?></p>
        <?php elseif ($userId <= 0): ?>
            <p class="muted">Nhập User ID để xem dữ liệu.</p>
        <?php elseif (empty($dbRows)): ?>
            <p class="muted">Không có row yêu thích nào của user #<?php echo $userId; ?> trong bảng <code>yeu_thich</code>.</p>
        <?php else: ?>
            <table>
                <tr><th>ID</th><th>Loại</th><th>Tour/Combo ID</th><th>Nhóm</th><th>Ngày thêm</th></tr>
                <?php foreach ($dbRows as $r): ?>
                    <tr>
                        <td><?php echo (int)$r['id']; ?></td>
                        <td><?php echo $r['id_tour'] ? 'tour' : 'combo'; ?></td>
                        <td><?php echo $r['id_tour'] ? (int)$r['id_tour'] : (int)$r['id_goi_combo']; ?></td>
                        <td><?php echo $r['id_nhom'] ? (int)$r['id_nhom'] : '—'; ?></td>
                        <td><?php echo esc($r['ngay_them']); ?></td>
                    </tr>
                <?php endforeach; ?>
            </table>
        <?php endif; ?>
    </div>

    <p class="sub">
        Trang test kiểm tra Redis yêu thích — thao tác ghi trực tiếp vào
        <code>tripto:favorite:user:*</code>. Key này được backend dùng khi người dùng bấm
        <b>Thêm vào yêu thích</b> trên trang tour/combo (xem <code>backend/RedisClient.php</code>,
        <code>backend/user.php</code>).
    </p>
</div>
</body>
</html>