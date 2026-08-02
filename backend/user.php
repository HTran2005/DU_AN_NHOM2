<?php
/**
 * ===============================================
 * UNIFIED USER & TOUR API SYSTEM
 * ===============================================
 * 
 * Consolidated API serving all user-related operations:
 * - Authentication (login, register)
 * - Profile Management (update profile, avatar)
 * - Tour Operations (get tours, filter, search, details)
 * - Combo Operations (get combos, filter, search)
 * - Location & Duration APIs
 * 
 * Request routing based on 'endpoint' parameter or action
 *
 * Supported Endpoints:
 * - auth (login, register, update_avatar, update_profile)
 * - get_tours
 * - get_tour_detail
 * - search_tours
 * - filter_tours
 * - get_combos
 * - search_combos
 * - filter_combos
 * - get_locations
 * - get_durations
 * - get_filter_data
 */

// =====================================================
// HEADERS & CONFIG
// =====================================================
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Import config
require_once __DIR__ . '/config.php';

// =====================================================
// AUTO-INITIALIZE DATABASE TABLES
// =====================================================

function initializeFavoriteTables() {
    global $conn;
    
    try {
        // Check if table already exists with correct schema
        $checkTableSQL = "SHOW TABLES LIKE 'nhom_yeuthich'";
        $tableResult = $conn->query($checkTableSQL);
        
        if (!$tableResult || $tableResult->num_rows === 0) {
            // Table doesn't exist, create it with correct schema
            $createGroupTableSQL = "CREATE TABLE nhom_yeuthich (
                id INT AUTO_INCREMENT PRIMARY KEY,
                id_nguoi_dung INT NOT NULL,
                ten_nhom VARCHAR(100) NOT NULL,
                ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (id_nguoi_dung) REFERENCES nguoi_dung(id) ON DELETE CASCADE
            )";
            
            if (!$conn->query($createGroupTableSQL)) {
                error_log("Error creating nhom_yeuthich: " . $conn->error);
            }
        } else {
            // Table exists, check if it has correct columns
            $describeSQL = "SHOW COLUMNS FROM nhom_yeuthich LIKE 'ten_nhom'";
            $colResult = $conn->query($describeSQL);
            
            // If ten_nhom column doesn't exist, table has wrong schema - need to migrate
            if (!$colResult || $colResult->num_rows === 0) {
                // Disable FK checks and drop old table
                $conn->query("SET FOREIGN_KEY_CHECKS=0");
                $conn->query("DROP TABLE nhom_yeuthich");
                $conn->query("SET FOREIGN_KEY_CHECKS=1");
                
                // Create new table with correct schema
                $createGroupTableSQL = "CREATE TABLE nhom_yeuthich (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    id_nguoi_dung INT NOT NULL,
                    ten_nhom VARCHAR(100) NOT NULL,
                    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (id_nguoi_dung) REFERENCES nguoi_dung(id) ON DELETE CASCADE
                )";
                
                if (!$conn->query($createGroupTableSQL)) {
                    error_log("Error recreating nhom_yeuthich with correct schema: " . $conn->error);
                }
            }
        }
        
        // Check if yeu_thich table exists
        $checkTableSQL = "SHOW TABLES LIKE 'yeu_thich'";
        $result = $conn->query($checkTableSQL);
        
        if ($result && $result->num_rows > 0) {
            // Table exists, check if id_nhom column exists
            $checkColumnSQL = "SHOW COLUMNS FROM yeu_thich LIKE 'id_nhom'";
            $colResult = $conn->query($checkColumnSQL);
            
            if (!$colResult || $colResult->num_rows === 0) {
                // Disable FK checks again to alter yeu_thich table
                $conn->query("SET FOREIGN_KEY_CHECKS=0");
                
                // Column doesn't exist, add it
                $addColSQL = "ALTER TABLE yeu_thich ADD COLUMN id_nhom INT NULL AFTER id_goi_combo";
                if (!$conn->query($addColSQL)) {
                    error_log("Error adding id_nhom column: " . $conn->error);
                }
                
                // Try to add foreign key constraint
                $addFKSQL = "ALTER TABLE yeu_thich ADD FOREIGN KEY (id_nhom) REFERENCES nhom_yeuthich(id) ON DELETE SET NULL";
                $conn->query($addFKSQL); // Silently fail if it already exists
                
                // Re-enable foreign key checks
                $conn->query("SET FOREIGN_KEY_CHECKS=1");
            }
        }
    } catch (Exception $e) {
        error_log("Database initialization error: " . $e->getMessage());
    }
}

// Initialize tables on every request (safe, uses IF NOT EXISTS)
initializeFavoriteTables();

// =====================================================
// HELPER FUNCTIONS
// =====================================================

/**
 * Xử lý và chuẩn hóa đường dẫn ảnh từ CSDL
 * Tất cả ảnh đều lưu trong thư mục /img (root của htdocs)
 * 
 * @param string $imageName Tên ảnh từ CSDL (ví dụ: "hagiang1.jpg")
 * @param string $defaultImage Ảnh mặc định nếu không có
 * @return string Đường dẫn ảnh tuyệt đối từ root
 */
function sanitizeImagePath($imageName, $defaultImage = 'default.jpg') {
    // Nếu rỗng, sử dụng ảnh mặc định
    if (empty($imageName) || !is_string($imageName)) {
        $imageName = $defaultImage;
    }
    
    // Trim khoảng trắng
    $imageName = trim($imageName);
    
    // Nếu là URL đầy đủ (http/https), giữ nguyên
    if (strpos($imageName, 'http') === 0) {
        return $imageName;
    }
    
    // Loại bỏ tất cả tiền tố đường dẫn (chỉ lấy tên file)
    $imageName = basename($imageName);
    
    // Nếu không có phần mở rộng, thêm .jpg
    if (empty($imageName) || strpos($imageName, '.') === false) {
        $imageName = $defaultImage;
    }
    
    // Sử dụng đường dẫn tuyệt đối từ root htdocs
    return '/img/' . $imageName;
}

// =====================================================
// MAIN ROUTING LOGIC
// =====================================================

try {
    // Determine endpoint and action
    $endpoint = isset($_REQUEST['endpoint']) ? trim($_REQUEST['endpoint']) : '';
    $action = isset($_REQUEST['action']) ? trim($_REQUEST['action']) : '';
    
    // If endpoint not specified, try to infer from action
    if (empty($endpoint)) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($action)) {
            $endpoint = 'auth';
        } else {
            $endpoint = isset($_GET['endpoint']) ? trim($_GET['endpoint']) : 'get_tours';
        }
    }
    
    // Route to appropriate handler
    switch ($endpoint) {
        case 'auth':
            handleAuth($action);
            break;
        case 'get_tours':
            handleGetTours();
            break;
        case 'get_tour_detail':
            handleGetTourDetail();
            break;
        case 'search_tours':
            handleSearchTours();
            break;
        case 'filter_tours':
            handleFilterTours();
            break;
        case 'get_combos':
            handleGetCombos();
            break;
        case 'get_combo_detail':
            handleGetComboDetail();
            break;
        case 'search_combos':
            handleSearchCombos();
            break;
        case 'filter_combos':
            handleFilterCombos();
            break;
        case 'get_locations':
            handleGetLocations();
            break;
        case 'get_durations':
            handleGetDurations();
            break;
        case 'get_filter_data':
            handleGetFilterData();
            break;
        case 'update_profile':
            handleUpdateProfileAPI();
            break;
        case 'create_booking':
            handleCreateBooking();
            break;
        case 'get_reviews':
            handleGetReviews();
            break;
        case 'get_all_reviews':
            handleGetAllReviews();
            break;
        case 'create_review':
            handleCreateReview();
            break;
        case 'get_booked_tours':
            handleGetBookedTours();
            break;
        case 'get_booking_detail':
            handleGetBookingDetail();
            break;
        case 'cancel_booking':
            handleCancelBooking();
            break;
        case 'get_invoice':
            handleGetInvoice();
            break;
        case 'get_khuyen_mai':
            handleGetKhuyenMai();
            break;
        case 'get_filter_destinations':
            handleGetFilterDestinations();
            break;
        case 'toggle_favorite':
            handleToggleFavorite();
            break;
        case 'check_favorite':
            handleCheckFavorite();
            break;
        case 'create_favorite_with_group':
            handleCreateFavoriteWithGroup();
            break;
        case 'toggle_combo_favorite':
            handleToggleComboFavorite();
            break;
        case 'check_combo_favorite':
            handleCheckComboFavorite();
            break;
        case 'create_combo_favorite_with_group':
            handleCreateComboFavoriteWithGroup();
            break;
        case 'remove_combo_favorite':
            handleRemoveComboFavorite();
            break;
        case 'get_favorite_groups':
            handleGetFavoriteGroups();
            break;
        case 'create_favorite_group':
            handleCreateFavoriteGroup();
            break;
        case 'get_user_favorites':
            handleGetUserFavorites();
            break;
        case 'get_favorites_by_group':
            handleGetFavoritesByGroup();
            break;
        case 'add_to_favorite_group':
            handleAddToFavoriteGroup();
            break;
        case 'delete_favorite_group':
            handleDeleteFavoriteGroup();
            break;
        case 'remove_tour_from_group':
            handleRemoveTourFromGroup();
            break;
        case 'init_favorite_tables':
            handleInitFavoriteTables();
            break;
        default:
            throw new Exception('Endpoint không hợp lệ: ' . htmlspecialchars($endpoint) . '. Vui lòng chỉ định endpoint hợp lệ.');
    }
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
    error_log("API Error: " . $e->getMessage());
} finally {
    closeConnection();
}

// =====================================================
// AUTH HANDLER - Consolidated from auth.php
// =====================================================

function handleAuth($action = '') {
    global $conn;
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'message' => 'Phương thức không được phép. Vui lòng sử dụng POST.'
        ]);
        exit;
    }
    
    if (isset($_POST['action'])) {
        $action = $_POST['action'];
    } else {
        $inputData = file_get_contents('php://input');
        $data = json_decode($inputData, true);
        if (isset($data['action'])) {
            $action = $data['action'];
        }
    }
    
    switch ($action) {
        case 'login':
            authLogin();
            break;
        case 'login_microsoft':
            authLoginMicrosoft();
            break;
        case 'register':
            authRegister();
            break;
        case 'update_avatar':
            authUpdateAvatar();
            break;
        case 'update_profile':
            authUpdateProfile();
            break;
        case 'update_profile_with_avatar':
            authUpdateProfileWithAvatar();
            break;
        default:
            throw new Exception('Auth action không hợp lệ. Vui lòng chỉ định: login, register, update_avatar, update_profile, hoặc update_profile_with_avatar');
    }
}

// =====================================================
// AUTH: MICROSOFT ENTRA ID LOGIN
// =====================================================

/**
 * Xác minh JWT id_token từ Microsoft Entra ID
 * Dùng khóa công khai RS256 từ Microsoft (JWKS) - không cần thư viện ngoài
 * 
 * @param string $idToken JWT do MSAL.js gửi lên
 * @return array Claims đã xác minh (email, name, oid,...)
 */
function verifyMicrosoftIdToken($idToken) {
    global $conn;
    
    if (empty(MS_CLIENT_ID)) {
        throw new Exception('Entra ID chưa được cấu hình trên server (thiếu MS_CLIENT_ID)');
    }
    
    // Tách 3 phần của JWT
    $parts = explode('.', $idToken);
    if (count($parts) !== 3) {
        throw new Exception('ID token không hợp lệ');
    }
    
    list($headerB64, $payloadB64, $signatureB64) = $parts;
    
    // Giải mã header + payload
    $header = json_decode(base64UrlDecode($headerB64), true);
    $payload = json_decode(base64UrlDecode($payloadB64), true);
    
    if (!$header || !$payload) {
        throw new Exception('ID token không thể giải mã');
    }
    
    // Kiểm tra thuật toán
    if (($header['alg'] ?? '') !== 'RS256') {
        throw new Exception('Thuật toán ký không được hỗ trợ');
    }
    
    // Kiểm tra thời hạn
    if (isset($payload['exp']) && $payload['exp'] < time()) {
        throw new Exception('ID token đã hết hạn');
    }
    if (isset($payload['nbf']) && $payload['nbf'] > time() + 300) {
        throw new Exception('ID token chưa có hiệu lực');
    }
    
    // Kiểm tra issuer (phải từ login.microsoftonline.com)
    $iss = $payload['iss'] ?? '';
    if (strpos($iss, 'login.microsoftonline.com') === false) {
        throw new Exception('Issuer không hợp lệ');
    }
    
    // Kiểm tra audience (phải trùng Client ID)
    if (($payload['aud'] ?? '') !== MS_CLIENT_ID) {
        throw new Exception('Audience không khớp với Client ID');
    }
    
    // Lấy khóa công khai JWKS từ Microsoft theo kid
    $kid = $header['kid'] ?? '';
    if (empty($kid)) {
        throw new Exception('Thiếu kid trong token');
    }
    
    $tenant = MS_TENANT_ID;
    $keysUrl = "https://login.microsoftonline.com/{$tenant}/discovery/v2.0/keys";
    
    // Cache JWKS trong file tạm để tránh gọi HTTP mỗi lần
    $cacheFile = sys_get_temp_dir() . '/ms_jwks_' . md5($tenant) . '.json';
    $jwks = null;
    if (file_exists($cacheFile) && (time() - filemtime($cacheFile) < 86400)) {
        $jwks = json_decode(file_get_contents($cacheFile), true);
    }
    
    if (!$jwks) {
        $ctx = stream_context_create(['http' => ['timeout' => 10]]);
        $keysJson = @file_get_contents($keysUrl, false, $ctx);
        if ($keysJson === false) {
            throw new Exception('Không thể lấy khóa xác minh từ Microsoft');
        }
        $keysData = json_decode($keysJson, true);
        $jwks = $keysData['keys'] ?? null;
        if ($jwks) {
            @file_put_contents($cacheFile, json_encode($jwks));
        }
    }
    
    if (!$jwks) {
        throw new Exception('Không nhận được khóa công khai từ Microsoft');
    }
    
    // Tìm key theo kid
    $pem = null;
    foreach ($jwks as $key) {
        if (($key['kid'] ?? '') === $kid && ($key['kty'] ?? '') === 'RSA') {
            $pem = jwkRsaToPem($key['n'], $key['e']);
            break;
        }
    }
    
    if (!$pem) {
        throw new Exception('Không tìm thấy khóa phù hợp (kid không khớp)');
    }
    
    // Xác minh chữ ký
    $dataToVerify = $headerB64 . '.' . $payloadB64;
    $signature = base64UrlDecode($signatureB64);
    $pubKey = openssl_pkey_get_public($pem);
    
    if (!$pubKey) {
        throw new Exception('Không thể tạo khóa công khai');
    }
    
    $verified = openssl_verify($dataToVerify, $signature, $pubKey, OPENSSL_ALGO_SHA256);
    openssl_free_key($pubKey);
    
    if ($verified !== 1) {
        throw new Exception('Chữ ký ID token không hợp lệ');
    }
    
    return $payload;
}

/**
 * Chuyển JWK (n, e) của RSA thành PEM public key
 */
function jwkRsaToPem($n, $e) {
    $nBin = base64UrlDecode($n);
    $eBin = base64UrlDecode($e);
    
    // ASN.1 INTEGER phải là số dương: thêm 0x00 nếu byte đầu có high bit set
    if (ord($nBin[0]) & 0x80) {
        $nBin = "\x00" . $nBin;
    }
    if (ord($eBin[0]) & 0x80) {
        $eBin = "\x00" . $eBin;
    }
    
    // Cấu trúc ASN.1: SEQUENCE { INTEGER n, INTEGER e }
    $nEnc = "\x02" . asn1Length(strlen($nBin)) . $nBin;
    $eEnc = "\x02" . asn1Length(strlen($eBin)) . $eBin;
    $rsa = "\x30" . asn1Length(strlen($nEnc) + strlen($eEnc)) . $nEnc . $eEnc;
    
    // PEM PKCS#1
    $pem = "-----BEGIN RSA PUBLIC KEY-----\n" . chunk_split(base64_encode($rsa), 64, "\n") . "-----END RSA PUBLIC KEY-----\n";
    return $pem;
}

/**
 * Mã hóa độ dài ASN.1 (DER length)
 */
function asn1Length($len) {
    if ($len < 0x80) {
        return chr($len);
    }
    $bytes = '';
    while ($len > 0) {
        $bytes = chr($len & 0xff) . $bytes;
        $len >>= 8;
    }
    return chr(0x80 | strlen($bytes)) . $bytes;
}

/**
 * Giải mã base64url sang binary
 */
function base64UrlDecode($data) {
    $remainder = strlen($data) % 4;
    if ($remainder) {
        $data .= str_repeat('=', 4 - $remainder);
    }
    return base64_decode(strtr($data, '-_', '+/'));
}

function authLoginMicrosoft() {
    global $conn;
    
    $inputData = file_get_contents('php://input');
    $data = json_decode($inputData, true);
    
    if ($data === null || empty($data['id_token'])) {
        throw new Exception('Thiếu id_token từ Microsoft');
    }
    
    $claims = verifyMicrosoftIdToken($data['id_token']);
    
    // Lấy thông tin từ claims
    $email = strtolower(trim($claims['email'] ?? $claims['preferred_username'] ?? ''));
    if (empty($email)) {
        throw new Exception('Không lấy được email từ tài khoản Microsoft');
    }
    
    $ten_dau  = trim($claims['given_name'] ?? '');
    $ten_cuoi = trim($claims['family_name'] ?? '');
    $fullName = trim($claims['name'] ?? '');
    $msOid    = $claims['oid'] ?? '';
    
    if (empty($ten_dau) && empty($ten_cuoi)) {
        // Tách họ tên từ name nếu không có given/family name
        $nameParts = preg_split('/\s+/', $fullName);
        if (count($nameParts) >= 2) {
            $ten_cuoi = array_pop($nameParts);
            $ten_dau  = implode(' ', $nameParts);
        } else {
            $ten_dau  = $fullName ?: 'Người dùng';
            $ten_cuoi = 'Microsoft';
        }
    }
    
    // Giới hạn độ dài theo schema (varchar 50)
    $ten_dau  = mb_substr($ten_dau, 0, 50);
    $ten_cuoi = mb_substr($ten_cuoi, 0, 50);
    
    // Tìm user theo email
    $checkSql = "SELECT * FROM nguoi_dung WHERE email = ?";
    $checkStmt = $conn->prepare($checkSql);
    if (!$checkStmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    $checkStmt->bind_param("s", $email);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult->num_rows > 0) {
        // User đã tồn tại -> cập nhật thông tin từ Microsoft (nếu cần)
        $user = $checkResult->fetch_assoc();
        $checkStmt->close();
    } else {
        // Tạo user mới từ tài khoản Microsoft
        $checkStmt->close();
        
        // Lưu oid Microsoft vào facebook_id (cột để lưu provider ID)
        $insertSql = "INSERT INTO nguoi_dung (ten_dau, ten_cuoi, email, facebook_id, so_dien_thoai, mat_khau, ngay_tao) 
                      VALUES (?, ?, ?, ?, NULL, '', NOW())";
        $insertStmt = $conn->prepare($insertSql);
        if (!$insertStmt) {
            throw new Exception("Lỗi prepare statement: " . $conn->error);
        }
        
        $emptyPassword = '';
        $msOidValue = $msOid ?: '';
        $insertStmt->bind_param("sssss", $ten_dau, $ten_cuoi, $email, $msOidValue, $emptyPassword);
        
        if (!$insertStmt->execute()) {
            throw new Exception("Lỗi khi tạo tài khoản: " . $insertStmt->error);
        }
        
        $newUserId = $insertStmt->insert_id;
        $insertStmt->close();
        
        $user = [
            'id' => $newUserId,
            'email' => $email,
            'ten_dau' => $ten_dau,
            'ten_cuoi' => $ten_cuoi,
            'so_dien_thoai' => null,
            'gioi_tinh' => null,
            'ngay_sinh' => null,
            'quoc_gia' => null,
            'dia_chi' => null,
            'ma_buu_chinh' => null,
            'avatar' => null,
            'anh_dai_dien' => null
        ];
    }
    
    session_start();
    $_SESSION['user_id'] = $user['id'];
    $_SESSION['email'] = $user['email'];
    $_SESSION['ten_dau'] = $user['ten_dau'];
    $_SESSION['ten_cuoi'] = $user['ten_cuoi'];
    $_SESSION['logged_in'] = true;
    $_SESSION['login_time'] = time();
    $_SESSION['auth_provider'] = 'microsoft';
    
    monitorTrackEvent('user_login', [
        'email' => $user['email'],
        'user_id' => $user['id'],
        'provider' => 'microsoft'
    ]);
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Đăng nhập bằng Microsoft thành công!',
        'user' => [
            'id' => $user['id'] ?? null,
            'email' => $user['email'] ?? null,
            'ten_dau' => $user['ten_dau'] ?? null,
            'ten_cuoi' => $user['ten_cuoi'] ?? null,
            'ho_ten' => (($user['ten_dau'] ?? '') . ' ' . ($user['ten_cuoi'] ?? '')),
            'phone' => $user['so_dien_thoai'] ?? null,
            'gioi_tinh' => $user['gioi_tinh'] ?? null,
            'ngay_sinh' => $user['ngay_sinh'] ?? null,
            'quoc_gia' => $user['quoc_gia'] ?? null,
            'dia_chi' => $user['dia_chi'] ?? null,
            'ma_buu_chinh' => $user['ma_buu_chinh'] ?? null,
            'avatar' => !empty($user['avatar']) ? $user['avatar'] : (!empty($user['anh_dai_dien']) ? $user['anh_dai_dien'] : '../image/avt_pr.jpg'),
            'anh_dai_dien' => !empty($user['avatar']) ? $user['avatar'] : (!empty($user['anh_dai_dien']) ? $user['anh_dai_dien'] : '../image/avt_pr.jpg')
        ]
    ]);
    exit;
}

// =====================================================
// AUTH: LOGIN
// =====================================================

function authLogin() {
    global $conn;
    
    $inputData = file_get_contents('php://input');
    $data = json_decode($inputData, true);
    
    if ($data === null) {
        throw new Exception('Dữ liệu JSON không hợp lệ');
    }
    
    $email      = isset($data['email']) ? strtolower(trim($data['email'])) : '';
    $password   = isset($data['password']) ? $data['password'] : '';
    
    if (empty($email)) {
        throw new Exception('Vui lòng nhập email');
    }
    if (empty($password)) {
        throw new Exception('Vui lòng nhập mật khẩu');
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new Exception('Email không hợp lệ');
    }
    
    $sql = "SELECT * FROM nguoi_dung WHERE email = ?";
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception('Email hoặc mật khẩu không chính xác');
    }
    
    $user = $result->fetch_assoc();
    $stmt->close();
    
    if (!password_verify($password, $user['mat_khau'])) {
        throw new Exception('Email hoặc mật khẩu không chính xác');
    }
    
    $updateSql = "UPDATE nguoi_dung SET luot_dang_nhap_cuoi = NOW() WHERE id = ?";
    $updateStmt = $conn->prepare($updateSql);
    if ($updateStmt) {
        $updateStmt->bind_param("i", $user['id']);
        $updateStmt->execute();
        $updateStmt->close();
    }
    
    session_start();
    $_SESSION['user_id'] = $user['id'];
    $_SESSION['email'] = $user['email'];
    $_SESSION['ten_dau'] = $user['ten_dau'];
    $_SESSION['ten_cuoi'] = $user['ten_cuoi'];
    $_SESSION['logged_in'] = true;
    $_SESSION['login_time'] = time();
    
    monitorTrackEvent('user_login', [
        'email' => $user['email'],
        'user_id' => $user['id']
    ]);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Đăng nhập thành công!',
        'user' => [
            'id' => $user['id'] ?? null,
            'email' => $user['email'] ?? null,
            'ten_dau' => $user['ten_dau'] ?? null,
            'ten_cuoi' => $user['ten_cuoi'] ?? null,
            'ho_ten' => (($user['ten_dau'] ?? '') . ' ' . ($user['ten_cuoi'] ?? '')),
            'phone' => $user['so_dien_thoai'] ?? null,
            'gioi_tinh' => $user['gioi_tinh'] ?? null,
            'ngay_sinh' => $user['ngay_sinh'] ?? null,
            'quoc_gia' => $user['quoc_gia'] ?? null,
            'dia_chi' => $user['dia_chi'] ?? null,
            'ma_buu_chinh' => $user['ma_buu_chinh'] ?? null,
            'avatar' => !empty($user['avatar']) ? $user['avatar'] : (!empty($user['anh_dai_dien']) ? $user['anh_dai_dien'] : '../image/avt_pr.jpg'),
            'anh_dai_dien' => !empty($user['avatar']) ? $user['avatar'] : (!empty($user['anh_dai_dien']) ? $user['anh_dai_dien'] : '../image/avt_pr.jpg')
        ]
    ]);
    exit;
}

// =====================================================
// AUTH: REGISTER
// =====================================================

function authRegister() {
    global $conn;
    
    $inputData = file_get_contents('php://input');
    $data = json_decode($inputData, true);
    
    if ($data === null) {
        throw new Exception('Dữ liệu JSON không hợp lệ');
    }
    
    $ten_dau    = isset($data['ten_dau']) ? trim($data['ten_dau']) : '';
    $ten_cuoi   = isset($data['ten_cuoi']) ? trim($data['ten_cuoi']) : '';
    $email      = isset($data['email']) ? strtolower(trim($data['email'])) : '';
    $so_dien_thoai = isset($data['so_dien_thoai']) ? trim($data['so_dien_thoai']) : '';
    $password   = isset($data['password']) ? $data['password'] : '';
    
    if (empty($ten_dau) || empty($ten_cuoi) || empty($email) || empty($so_dien_thoai) || empty($password)) {
        throw new Exception('Vui lòng điền tất cả các trường bắt buộc');
    }
    
    if (strlen($ten_dau) < 2 || strlen($ten_dau) > 50) {
        throw new Exception('Họ phải từ 2-50 ký tự');
    }
    if (strlen($ten_cuoi) < 2 || strlen($ten_cuoi) > 50) {
        throw new Exception('Tên phải từ 2-50 ký tự');
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new Exception('Email không hợp lệ');
    }
    if (!preg_match('/^[0-9]{10,11}$/', preg_replace('/[^\d]/', '', $so_dien_thoai))) {
        throw new Exception('Số điện thoại phải từ 10-11 chữ số');
    }
    if (strlen($password) < 6) {
        throw new Exception('Mật khẩu phải tối thiểu 6 ký tự');
    }
    if (strlen($password) > 100) {
        throw new Exception('Mật khẩu quá dài');
    }
    
    $checkSql = "SELECT id FROM nguoi_dung WHERE email = ?";
    $checkStmt = $conn->prepare($checkSql);
    
    if (!$checkStmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $checkStmt->bind_param("s", $email);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult->num_rows > 0) {
        throw new Exception('Email này đã được đăng ký. Vui lòng sử dụng email khác hoặc đăng nhập.');
    }
    $checkStmt->close();
    
    $hashedPassword = password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]);
    
    $insertSql = "INSERT INTO nguoi_dung (ten_dau, ten_cuoi, email, so_dien_thoai, mat_khau, ngay_tao) 
                  VALUES (?, ?, ?, ?, ?, NOW())";
    
    $insertStmt = $conn->prepare($insertSql);
    
    if (!$insertStmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $insertStmt->bind_param("sssss", $ten_dau, $ten_cuoi, $email, $so_dien_thoai, $hashedPassword);
    
    if (!$insertStmt->execute()) {
        throw new Exception("Lỗi khi lưu dữ liệu: " . $insertStmt->error);
    }
    
    $new_user_id = $insertStmt->insert_id;
    $insertStmt->close();
    
    monitorTrackEvent('user_register', [
        'email' => $email,
        'user_id' => $new_user_id
    ]);

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Đăng ký thành công! Tài khoản đã được tạo. Vui lòng đăng nhập để tiếp tục.',
        'user_id' => $new_user_id
    ]);
    exit;
}

// =====================================================
// AUTH: UPDATE AVATAR
// =====================================================

function authUpdateAvatar() {
    global $conn;
    
    if (!isset($_FILES['avatar']) || $_FILES['avatar']['error'] !== UPLOAD_ERR_OK) {
        throw new Exception('Vui lòng chọn một file ảnh hợp lệ');
    }
    
    $user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
    if ($user_id <= 0) {
        throw new Exception('ID người dùng không hợp lệ');
    }
    
    $checkSql = "SELECT id FROM nguoi_dung WHERE id = ?";
    $checkStmt = $conn->prepare($checkSql);
    if (!$checkStmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $checkStmt->bind_param("i", $user_id);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult->num_rows === 0) {
        throw new Exception('Người dùng không tồn tại');
    }
    $checkStmt->close();
    
    $file = $_FILES['avatar'];
    $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    $allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    
    if (!in_array($file['type'], $allowedTypes)) {
        throw new Exception('Chỉ hỗ trợ các định dạng ảnh: JPG, PNG, GIF, WebP');
    }
    
    $fileExt = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (!in_array($fileExt, $allowedExtensions)) {
        throw new Exception('Loại file không hợp lệ');
    }
    
    if ($file['size'] > 5 * 1024 * 1024) {
        throw new Exception('Kích thước file không được vượt quá 5MB');
    }
    
    $uploadDir = 'image/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }
    
    $filename = 'avatar_user_' . $user_id . '.' . $fileExt;
    $filepath = $uploadDir . $filename;
    $relativePath = '../image/' . $filename;
    
    foreach ($allowedExtensions as $ext) {
        $oldFile = $uploadDir . 'avatar_user_' . $user_id . '.' . $ext;
        if (file_exists($oldFile) && $oldFile !== $filepath) {
            unlink($oldFile);
        }
    }
    
    if (!move_uploaded_file($file['tmp_name'], $filepath)) {
        throw new Exception('Không thể lưu file ảnh');
    }
    
    $updateSql = "UPDATE nguoi_dung SET avatar = ? WHERE id = ?";
    $updateStmt = $conn->prepare($updateSql);
    
    if ($updateStmt) {
        $updateStmt->bind_param("si", $relativePath, $user_id);
        $updateStmt->execute();
        $updateStmt->close();
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Cập nhật ảnh đại diện thành công!',
        'avatar_url' => $relativePath
    ]);
    exit;
}

// =====================================================
// AUTH: UPDATE PROFILE (JSON)
// =====================================================

function authUpdateProfile() {
    global $conn;
    
    $inputData = file_get_contents('php://input');
    $data = json_decode($inputData, true);
    
    if ($data === null) {
        throw new Exception('Dữ liệu JSON không hợp lệ');
    }
    
    $user_id = isset($data['user_id']) ? intval($data['user_id']) : 0;
    if ($user_id <= 0) {
        throw new Exception('ID người dùng không hợp lệ');
    }
    
    $checkSql = "SELECT id FROM nguoi_dung WHERE id = ?";
    $checkStmt = $conn->prepare($checkSql);
    if (!$checkStmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $checkStmt->bind_param("i", $user_id);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult->num_rows === 0) {
        throw new Exception('Người dùng không tồn tại');
    }
    $checkStmt->close();
    
    $fields = [];
    $values = [];
    $types = '';
    
    $allowedFields = [
        'ten_dau' => 's',
        'ten_cuoi' => 's',
        'so_dien_thoai' => 's',
        'gioi_tinh' => 's',
        'ngay_sinh' => 's',
        'quoc_gia' => 's',
        'dia_chi' => 's',
        'ma_buu_chinh' => 's'
    ];
    
    $hasUpdates = false;
    foreach ($allowedFields as $field => $type) {
        if (isset($data[$field]) && $data[$field] !== '') {
            $fields[] = "$field = ?";
            $values[] = $data[$field];
            $types .= $type;
            $hasUpdates = true;
        }
    }
    
    if (!$hasUpdates) {
        throw new Exception('Không có dữ liệu nào để cập nhật');
    }
    
    $sql = "UPDATE nguoi_dung SET " . implode(", ", $fields) . " WHERE id = ?";
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $values[] = $user_id;
    $types .= 'i';
    
    $stmt->bind_param($types, ...$values);
    
    if (!$stmt->execute()) {
        throw new Exception("Lỗi thực thi: " . $stmt->error);
    }
    
    $stmt->close();
    
    $userSql = "SELECT id, ten_dau, ten_cuoi, email, so_dien_thoai, gioi_tinh, ngay_sinh, quoc_gia, dia_chi, ma_buu_chinh 
                FROM nguoi_dung WHERE id = ?";
    $userStmt = $conn->prepare($userSql);
    
    if (!$userStmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $userStmt->bind_param("i", $user_id);
    $userStmt->execute();
    $userResult = $userStmt->get_result();
    $user = $userResult->fetch_assoc();
    $userStmt->close();
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Cập nhật thông tin thành công!',
        'user' => [
            'id' => $user['id'],
            'email' => $user['email'],
            'ten_dau' => $user['ten_dau'],
            'ten_cuoi' => $user['ten_cuoi'],
            'ho_ten' => $user['ten_dau'] . ' ' . $user['ten_cuoi'],
            'phone' => $user['so_dien_thoai'],
            'gioi_tinh' => $user['gioi_tinh'],
            'ngay_sinh' => $user['ngay_sinh'],
            'quoc_gia' => $user['quoc_gia'],
            'dia_chi' => $user['dia_chi'],
            'ma_buu_chinh' => $user['ma_buu_chinh']
        ]
    ]);
    exit;
}

// =====================================================
// AUTH: UPDATE PROFILE WITH AVATAR (form-data)
// =====================================================

function authUpdateProfileWithAvatar() {
    global $conn;
    
    $user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
    if ($user_id <= 0) {
        throw new Exception('ID người dùng không hợp lệ');
    }
    
    $checkSql = "SELECT id FROM nguoi_dung WHERE id = ?";
    $checkStmt = $conn->prepare($checkSql);
    if (!$checkStmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $checkStmt->bind_param("i", $user_id);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult->num_rows === 0) {
        throw new Exception('Người dùng không tồn tại');
    }
    $checkStmt->close();
    
    $fields = [];
    $values = [];
    $types = '';
    
    $allowedFields = [
        'ten_dau' => 's',
        'ten_cuoi' => 's',
        'so_dien_thoai' => 's',
        'gioi_tinh' => 's',
        'ngay_sinh' => 's',
        'quoc_gia' => 's',
        'dia_chi' => 's',
        'ma_buu_chinh' => 's'
    ];
    
    foreach ($allowedFields as $field => $type) {
        if (isset($_POST[$field]) && $_POST[$field] !== '') {
            $fields[] = "$field = ?";
            $values[] = $_POST[$field];
            $types .= $type;
        }
    }
    
    $avatarUrl = null;
    if (isset($_FILES['avatar']) && $_FILES['avatar']['error'] === UPLOAD_ERR_OK) {
        $file = $_FILES['avatar'];
        $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
        $allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        
        if (!in_array($file['type'], $allowedTypes)) {
            throw new Exception('Chỉ hỗ trợ các định dạng ảnh: JPG, PNG, GIF, WebP');
        }
        
        $fileExt = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        if (!in_array($fileExt, $allowedExtensions)) {
            throw new Exception('Loại file không hợp lệ');
        }
        
        if ($file['size'] > 5 * 1024 * 1024) {
            throw new Exception('Kích thước file không được vượt quá 5MB');
        }
        
        $uploadDir = 'image/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }
        
        $filename = 'avatar_user_' . $user_id . '.' . $fileExt;
        $filepath = $uploadDir . $filename;
        $avatarUrl = '../image/' . $filename;
        
        foreach ($allowedExtensions as $ext) {
            $oldFile = $uploadDir . 'avatar_user_' . $user_id . '.' . $ext;
            if (file_exists($oldFile) && $oldFile !== $filepath) {
                unlink($oldFile);
            }
        }
        
        if (!move_uploaded_file($file['tmp_name'], $filepath)) {
            throw new Exception('Không thể lưu file ảnh');
        }
        
        $fields[] = 'anh_dai_dien = ?';
        $values[] = $avatarUrl;
        $types .= 's';
    }
    
    if (count($fields) === 0) {
        throw new Exception('Không có dữ liệu nào để cập nhật');
    }
    
    $sql = "UPDATE nguoi_dung SET " . implode(", ", $fields) . " WHERE id = ?";
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $values[] = $user_id;
    $types .= 'i';
    
    $stmt->bind_param($types, ...$values);
    
    if (!$stmt->execute()) {
        throw new Exception("Lỗi thực thi: " . $stmt->error);
    }
    
    $stmt->close();
    
    $userSql = "SELECT id, ten_dau, ten_cuoi, email, so_dien_thoai, gioi_tinh, ngay_sinh, quoc_gia, dia_chi, ma_buu_chinh, anh_dai_dien 
                FROM nguoi_dung WHERE id = ?";
    $userStmt = $conn->prepare($userSql);
    
    if (!$userStmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $userStmt->bind_param("i", $user_id);
    $userStmt->execute();
    $userResult = $userStmt->get_result();
    $user = $userResult->fetch_assoc();
    $userStmt->close();
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Cập nhật thông tin và ảnh đại diện thành công!',
        'user' => [
            'id' => $user['id'],
            'email' => $user['email'],
            'ten_dau' => $user['ten_dau'],
            'ten_cuoi' => $user['ten_cuoi'],
            'ho_ten' => $user['ten_dau'] . ' ' . $user['ten_cuoi'],
            'phone' => $user['so_dien_thoai'],
            'gioi_tinh' => $user['gioi_tinh'],
            'ngay_sinh' => $user['ngay_sinh'],
            'quoc_gia' => $user['quoc_gia'],
            'dia_chi' => $user['dia_chi'],
            'ma_buu_chinh' => $user['ma_buu_chinh'],
            'anh_dai_dien' => $user['anh_dai_dien']
        ],
        'avatar_url' => $avatarUrl
    ]);
    exit;
}

// =====================================================
// TOUR HANDLERS
// =====================================================

function handleGetTours() {
    global $conn;
    
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 999;
    $offset = isset($_GET['offset']) ? intval($_GET['offset']) : 0;
    $search = isset($_GET['search']) ? trim($_GET['search']) : '';
    $sort = isset($_GET['sort']) ? trim($_GET['sort']) : 'newest';
    
    if ($limit < 1 || $limit > 1000) {
        $limit = 999;
    }
    if ($offset < 0) {
        $offset = 0;
    }
    
    $sql = "SELECT t.id, t.ten, t.mo_ta, t.gia, t.so_ngay, t.so_nguoi_toi_da, t.url_anh_chinh, t.danh_gia, t.so_danh_gia, t.trang_thai, 
                   dd.ten as dia_diem_ten, dd.quoc_gia
            FROM tour t 
            LEFT JOIN dia_diem dd ON t.id_dia_diem = dd.id 
            WHERE t.trang_thai = 'Hoạt động'";
    
    if (!empty($search)) {
        $sql .= " AND (t.ten LIKE ? OR t.mo_ta LIKE ?)";
    }
    
    switch ($sort) {
        case 'popular':
            $sql .= " ORDER BY t.so_danh_gia DESC";
            break;
        case 'price-low':
            $sql .= " ORDER BY t.gia ASC";
            break;
        case 'price-high':
            $sql .= " ORDER BY t.gia DESC";
            break;
        case 'newest':
            $sql .= " ORDER BY t.id DESC";
            break;
        case 'random':
        default:
            $sql .= " ORDER BY RAND()";
            break;
    }
    
    $sql .= " LIMIT ? OFFSET ?";
    
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    if (!empty($search)) {
        $searchTerm = '%' . $search . '%';
        $stmt->bind_param("ssii", $searchTerm, $searchTerm, $limit, $offset);
    } else {
        $stmt->bind_param("ii", $limit, $offset);
    }
    
    if (!$stmt->execute()) {
        throw new Exception("Lỗi thực thi query: " . $stmt->error);
    }
    
    $result = $stmt->get_result();
    $tours = [];
    
    while ($row = $result->fetch_assoc()) {
        $gia = floatval($row['gia']);
        
        $badge = '';
        $badgeType = '';
        if ($row['so_danh_gia'] > 200) {
            $badge = 'Bán Chạy';
            $badgeType = 'featured';
        } elseif ($row['so_danh_gia'] > 150) {
            $badge = 'Yêu Thích';
            $badgeType = 'featured';
        } else {
            $badge = 'Mới';
            $badgeType = 'default';
        }
        
        $location = '';
        if (!empty($row['dia_diem_ten'])) {
            $location = $row['dia_diem_ten'];
            if (!empty($row['quoc_gia'])) {
                $location .= ', ' . $row['quoc_gia'];
            }
        }
        
        $url_anh = $row['url_anh_chinh'];
        if (!empty($url_anh) && strpos($url_anh, '/') !== 0) {
            $url_anh = '/img/' . $url_anh;
        }
        
        $tours[] = [
            'id' => intval($row['id']),
            'ten' => $row['ten'],
            'mo_ta' => $row['mo_ta'],
            'location' => $location,
            'gia' => $gia,
            'gia_formatted' => number_format($gia, 0, ',', '.'),
            'so_ngay' => intval($row['so_ngay']),
            'so_nguoi_toi_da' => intval($row['so_nguoi_toi_da']),
            'url_anh_chinh' => $url_anh,
            'danh_gia' => floatval($row['danh_gia']),
            'so_danh_gia' => intval($row['so_danh_gia']),
            'badge' => $badge,
            'badge_type' => $badgeType,
            'duration' => intval($row['so_ngay']) . 'N' . (intval($row['so_ngay']) - 1) . 'Đ'
        ];
    }
    
    $stmt->close();
    
    $countSql = "SELECT COUNT(*) as total FROM tour t WHERE t.trang_thai = 'Hoạt động'";
    if (!empty($search)) {
        $countSql .= " AND (t.ten LIKE ? OR t.mo_ta LIKE ?)";
    }
    
    $countStmt = $conn->prepare($countSql);
    if (!empty($search)) {
        $countStmt->bind_param("ss", $searchTerm, $searchTerm);
    }
    $countStmt->execute();
    $countResult = $countStmt->get_result();
    $totalRow = $countResult->fetch_assoc();
    $total = intval($totalRow['total']);
    $countStmt->close();
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => $tours,
        'pagination' => [
            'limit' => $limit,
            'offset' => $offset,
            'total' => $total,
            'page' => floor($offset / $limit) + 1,
            'total_pages' => ceil($total / $limit)
        ]
    ]);
    exit;
}

function handleGetTourDetail() {
    global $conn;
    
    $tour_id = isset($_GET['id']) ? intval($_GET['id']) : 0;
    
    if (!$tour_id) {
        echo json_encode([
            'success' => false,
            'message' => 'Tour ID không hợp lệ'
        ]);
        exit;
    }
    
    // Get tour information
    $sql = "SELECT t.*, dd.ten as dia_diem_ten 
            FROM tour t 
            LEFT JOIN dia_diem dd ON t.id_dia_diem = dd.id 
            WHERE t.id = ?";
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi chuẩn bị câu lệnh: ' . $conn->error
        ]);
        exit;
    }
    
    $stmt->bind_param("i", $tour_id);
    if (!$stmt->execute()) {
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi thực thi câu lệnh: ' . $stmt->error
        ]);
        exit;
    }
    
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Tour không tìm thấy'
        ]);
        exit;
    }
    
    $tour = $result->fetch_assoc();
    $stmt->close();
    
    // Cast numeric fields to proper types
    $tour['id'] = (int)$tour['id'];
    $tour['gia'] = (float)$tour['gia'];
    $tour['danh_gia'] = $tour['danh_gia'] !== null ? (float)$tour['danh_gia'] : null;
    $tour['so_danh_gia'] = (int)$tour['so_danh_gia'];
    $tour['so_ngay'] = (int)$tour['so_ngay'];
    
    // Format price
    $tour['gia_formatted'] = '$' . number_format($tour['gia'], 0);
    
    // Set default image if missing
    if (empty($tour['url_anh_chinh'])) {
        $tour['url_anh_chinh'] = 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&h=400&fit=crop';
    } elseif (strpos($tour['url_anh_chinh'], 'http') !== 0) {
        $tour['url_anh_chinh'] = '/img/' . $tour['url_anh_chinh'];
    }
    
    // Initialize schedule array
    $tour['schedule'] = [];
    
    // Query lịch trình tour (schedule days)
    $schedule_sql = "SELECT * FROM lich_trinh_tour WHERE id_tour = ? ORDER BY so_ngay ASC";
    $schedule_stmt = $conn->prepare($schedule_sql);
    
    if (!$schedule_stmt) {
        error_log("Schedule Query Prepare Error: " . $conn->error);
        // Continue without schedule data
    } else {
        $schedule_stmt->bind_param("i", $tour_id);
        
        if (!$schedule_stmt->execute()) {
            error_log("Schedule Query Execute Error: " . $schedule_stmt->error);
        } else {
            $schedule_result = $schedule_stmt->get_result();
            
            if ($schedule_result && $schedule_result->num_rows > 0) {
                while ($schedule_row = $schedule_result->fetch_assoc()) {
                    // Get details for this schedule day
                    $schedule_id = (int)$schedule_row['id'];
                    
                    $detail_sql = "SELECT * FROM lich_trinh_chi_tiet WHERE lich_trinh_id = ? ORDER BY id ASC";
                    $detail_stmt = $conn->prepare($detail_sql);
                    
                    $schedule_row['details'] = [];
                    
                    if ($detail_stmt) {
                        $detail_stmt->bind_param("i", $schedule_id);
                        
                        if ($detail_stmt->execute()) {
                            $detail_result = $detail_stmt->get_result();
                            
                            if ($detail_result && $detail_result->num_rows > 0) {
                                while ($detail_row = $detail_result->fetch_assoc()) {
                                    $schedule_row['details'][] = $detail_row;
                                }
                            }
                        } else {
                            error_log("Detail Query Execute Error for schedule_id=$schedule_id: " . $detail_stmt->error);
                        }
                        
                        $detail_stmt->close();
                    } else {
                        error_log("Detail Query Prepare Error: " . $conn->error);
                    }
                    
                    $tour['schedule'][] = $schedule_row;
                }
            }
        }
        
        $schedule_stmt->close();
    }
    
    echo json_encode([
        'success' => true,
        'data' => $tour
    ]);
    exit;
}

function handleSearchTours() {
    global $conn;
    
    $q = isset($_REQUEST['q']) ? trim($_REQUEST['q']) : '';
    $destination = isset($_REQUEST['destination']) ? trim($_REQUEST['destination']) : '';
    $tourType = isset($_REQUEST['tourType']) ? trim($_REQUEST['tourType']) : '';
    $category = isset($_REQUEST['category']) ? trim($_REQUEST['category']) : ''; // Loại tour từ filter (single)
    $region = isset($_REQUEST['region']) ? trim($_REQUEST['region']) : ''; // Vùng miền
    $duration = isset($_REQUEST['duration']) ? trim($_REQUEST['duration']) : ''; // Thời lượng (string: "1", "2", "3", "4+")
    $departDate = isset($_REQUEST['departDate']) ? trim($_REQUEST['departDate']) : '';
    $maxPrice = isset($_REQUEST['maxPrice']) ? floatval($_REQUEST['maxPrice']) : PHP_INT_MAX;
    $minRating = isset($_REQUEST['minRating']) ? floatval($_REQUEST['minRating']) : 0;
    $limit = isset($_REQUEST['limit']) ? intval($_REQUEST['limit']) : 20;
    $offset = isset($_REQUEST['offset']) ? intval($_REQUEST['offset']) : 0;
    $sort = isset($_REQUEST['sort']) ? trim($_REQUEST['sort']) : 'relevance';
    
    if ($limit < 1 || $limit > 100) {
        $limit = 20;
    }
    if ($offset < 0) {
        $offset = 0;
    }
    
    $conditions = [];
    $params = [];
    $paramTypes = '';
    
    $conditions[] = "t.trang_thai = 'Hoạt động'";
    
    if (!empty($q)) {
        $conditions[] = "(t.ten LIKE ? OR t.mo_ta LIKE ? OR dd.ten LIKE ?)";
        $searchTerm = '%' . $q . '%';
        $params[] = $searchTerm;
        $params[] = $searchTerm;
        $params[] = $searchTerm;
        $paramTypes .= 'sss';
    }
    
    if (!empty($destination)) {
        $conditions[] = "(t.ten LIKE ? OR dd.ten LIKE ? OR dd.quoc_gia LIKE ?)";
        $destTerm = '%' . $destination . '%';
        $params[] = $destTerm;
        $params[] = $destTerm;
        $params[] = $destTerm;
        $paramTypes .= 'sss';
    }
    
    if (!empty($tourType)) {
        $typeMap = [
            'bien-dao' => 'biển',
            'gia-dinh' => 'gia',
            'nghi-duong' => 'nghỉ',
            'mao-hiem' => 'mạo',
            'van-hoa' => 'văn'
        ];
        $normalizedType = isset($typeMap[$tourType]) ? $typeMap[$tourType] : $tourType;
        
        $conditions[] = "(t.loai_tour LIKE ? OR t.ten LIKE ? OR t.mo_ta LIKE ?)";
        $typeTerm = '%' . $normalizedType . '%';
        $params[] = $typeTerm;
        $params[] = $typeTerm;
        $params[] = $typeTerm;
        $paramTypes .= 'sss';
    }
    
    // Lọc loại tour từ filter (single select)
    if (!empty($category)) {
        $conditions[] = "t.loai_tour = ?";
        $params[] = $category;
        $paramTypes .= 's';
    }
    
    // Thêm filter vùng miền
    if (!empty($region)) {
        $conditions[] = "dd.vung_mien = ?";
        $params[] = $region;
        $paramTypes .= 's';
    }
    
    // Lọc theo thời lượng
    if (!empty($duration)) {
        if ($duration === '4+') {
            // Trên 3 ngày → so_ngay >= 4
            $conditions[] = "t.so_ngay >= ?";
            $params[] = 4;
            $paramTypes .= 'i';
        } else {
            // 1, 2, 3 → so_ngay chính xác
            $conditions[] = "t.so_ngay = ?";
            $params[] = intval($duration);
            $paramTypes .= 'i';
        }
    }
    
    if (!empty($departDate)) {
        $conditions[] = "t.ngay_khoi_hanh >= ?";
        $params[] = $departDate;
        $paramTypes .= 's';
    }
    
    if ($maxPrice < PHP_INT_MAX) {
        $conditions[] = "t.gia <= ?";
        $params[] = $maxPrice;
        $paramTypes .= 'd';
    }
    
    if ($minRating > 0) {
        $conditions[] = "t.danh_gia >= ?";
        $params[] = $minRating;
        $paramTypes .= 'd';
    }
    
    $whereClause = implode(' AND ', $conditions);
    
    $sql = "SELECT t.id, t.ten, t.mo_ta, t.gia, t.so_ngay, t.so_nguoi_toi_da, t.url_anh_chinh, t.danh_gia, t.so_danh_gia, t.trang_thai, 
                   dd.ten as dia_diem_ten, dd.quoc_gia, dd.vung_mien
            FROM tour t 
            LEFT JOIN dia_diem dd ON t.id_dia_diem = dd.id 
            WHERE {$whereClause}";
    
    switch ($sort) {
        case 'price-asc':
            $sql .= " ORDER BY t.gia ASC";
            break;
        case 'price-desc':
            $sql .= " ORDER BY t.gia DESC";
            break;
        case 'rating-desc':
            $sql .= " ORDER BY t.danh_gia DESC";
            break;
        case 'newest':
            $sql .= " ORDER BY t.id DESC";
            break;
        case 'relevance':
        default:
            $sql .= " ORDER BY t.danh_gia DESC, t.so_danh_gia DESC";
            break;
    }
    
    $sql .= " LIMIT ? OFFSET ?";
    $params[] = $limit;
    $params[] = $offset;
    $paramTypes .= 'ii';
    
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    if (!empty($paramTypes)) {
        $stmt->bind_param($paramTypes, ...$params);
    }
    
    if (!$stmt->execute()) {
        throw new Exception("Lỗi thực thi query: " . $stmt->error);
    }
    
    $result = $stmt->get_result();
    $tours = [];
    
    while ($row = $result->fetch_assoc()) {
        $gia = floatval($row['gia']);
        
        $badge = '';
        $badgeType = 'default';
        
        if ($row['so_danh_gia'] > 200) {
            $badge = 'Bán Chạy';
            $badgeType = 'featured';
        } elseif ($row['so_danh_gia'] > 150) {
            $badge = 'Yêu Thích';
            $badgeType = 'featured';
        } else {
            $badge = 'Mới';
            $badgeType = 'default';
        }
        
        $location = '';
        if (!empty($row['dia_diem_ten'])) {
            $location = $row['dia_diem_ten'];
            if (!empty($row['quoc_gia'])) {
                $location .= ', ' . $row['quoc_gia'];
            }
        }
        
        $url_anh = $row['url_anh_chinh'];
        if (!empty($url_anh) && strpos($url_anh, '/') !== 0) {
            $url_anh = '/img/' . $url_anh;
        }
        
        $tours[] = [
            'id' => intval($row['id']),
            'ten' => $row['ten'],
            'mo_ta' => $row['mo_ta'],
            'location' => $location,
            'gia' => $gia,
            'gia_formatted' => number_format($gia, 0, ',', '.'),
            'so_ngay' => intval($row['so_ngay']),
            'so_nguoi_toi_da' => intval($row['so_nguoi_toi_da']),
            'url_anh_chinh' => $url_anh,
            'danh_gia' => floatval($row['danh_gia']),
            'so_danh_gia' => intval($row['so_danh_gia']),
            'badge' => $badge,
            'badge_type' => $badgeType,
            'duration' => intval($row['so_ngay']) . 'N' . (intval($row['so_ngay']) - 1) . 'Đ'
        ];
    }
    
    $stmt->close();
    
    $countConditions = [];
    $countParams = [];
    $countParamTypes = '';
    
    $countConditions[] = "t.trang_thai = 'Hoạt động'";
    
    if (!empty($q)) {
        $countConditions[] = "(t.ten LIKE ? OR t.mo_ta LIKE ? OR dd.ten LIKE ?)";
        $countParams[] = $searchTerm;
        $countParams[] = $searchTerm;
        $countParams[] = $searchTerm;
        $countParamTypes .= 'sss';
    }
    
    if (!empty($destination)) {
        $countConditions[] = "(t.ten LIKE ? OR dd.ten LIKE ? OR dd.quoc_gia LIKE ?)";
        $countParams[] = $destTerm;
        $countParams[] = $destTerm;
        $countParams[] = $destTerm;
        $countParamTypes .= 'sss';
    }
    
    if (!empty($tourType)) {
        $typeMap = [
            'bien-dao' => 'biển',
            'gia-dinh' => 'gia',
            'nghi-duong' => 'nghỉ',
            'mao-hiem' => 'mạo',
            'van-hoa' => 'văn'
        ];
        $normalizedType = isset($typeMap[$tourType]) ? $typeMap[$tourType] : $tourType;
        
        $countConditions[] = "(t.loai_tour LIKE ? OR t.ten LIKE ? OR t.mo_ta LIKE ?)";
        $countTypeTerm = '%' . $normalizedType . '%';
        $countParams[] = $countTypeTerm;
        $countParams[] = $countTypeTerm;
        $countParams[] = $countTypeTerm;
        $countParamTypes .= 'sss';
    }
    
    // Lọc loại tour từ filter vào count query (single select)
    if (!empty($category)) {
        $countConditions[] = "t.loai_tour = ?";
        $countParams[] = $category;
        $countParamTypes .= 's';
    }
    
    // Thêm filter vùng miền vào count query
    if (!empty($region)) {
        $countConditions[] = "dd.vung_mien = ?";
        $countParams[] = $region;
        $countParamTypes .= 's';
    }
    
    // Lọc theo thời lượng vào count query
    if (!empty($duration)) {
        if ($duration === '4+') {
            // Trên 3 ngày → so_ngay >= 4
            $countConditions[] = "t.so_ngay >= ?";
            $countParams[] = 4;
            $countParamTypes .= 'i';
        } else {
            // 1, 2, 3 → so_ngay chính xác
            $countConditions[] = "t.so_ngay = ?";
            $countParams[] = intval($duration);
            $countParamTypes .= 'i';
        }
    }
    
    if (!empty($departDate)) {
        $countConditions[] = "t.ngay_khoi_hanh >= ?";
        $countParams[] = $departDate;
        $countParamTypes .= 's';
    }
    
    if ($maxPrice < PHP_INT_MAX) {
        $countConditions[] = "t.gia <= ?";
        $countParams[] = $maxPrice;
        $countParamTypes .= 'd';
    }
    
    if ($minRating > 0) {
        $countConditions[] = "t.danh_gia >= ?";
        $countParams[] = $minRating;
        $countParamTypes .= 'd';
    }
    
    $countWhereClause = implode(' AND ', $countConditions);
    $countSql = "SELECT COUNT(*) as total FROM tour t LEFT JOIN dia_diem dd ON t.id_dia_diem = dd.id WHERE {$countWhereClause}";
    
    $countStmt = $conn->prepare($countSql);
    
    if (!empty($countParamTypes)) {
        $countStmt->bind_param($countParamTypes, ...$countParams);
    }
    
    $countStmt->execute();
    $countResult = $countStmt->get_result();
    $totalRow = $countResult->fetch_assoc();
    $total = intval($totalRow['total']);
    $countStmt->close();
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => $tours,
        'pagination' => [
            'limit' => $limit,
            'offset' => $offset,
            'total' => $total,
            'page' => floor($offset / $limit) + 1,
            'total_pages' => ceil($total / $limit)
        ],
        'message' => "Tìm thấy {$total} tour phù hợp"
    ]);
    exit;
}

function handleFilterTours() {
    global $conn;
    
    $location = isset($_GET['location']) && $_GET['location'] != '' ? $_GET['location'] : null;
    $tour_type = isset($_GET['tour_type']) && $_GET['tour_type'] != '' ? $_GET['tour_type'] : null;
    $duration = isset($_GET['duration']) && $_GET['duration'] != '' ? (int)$_GET['duration'] : null;
    $price_min = isset($_GET['price_min']) ? (int)$_GET['price_min'] : 0;
    $price_max = isset($_GET['price_max']) ? (int)$_GET['price_max'] : 999999999;
    
    $sql = "SELECT 
                t.id,
                t.ten,
                t.mo_ta,
                t.gia,
                t.so_ngay,
                t.url_anh_chinh,
                t.danh_gia,
                t.so_danh_gia,
                t.loai_tour,
                dd.ten AS location
            FROM tour t
            LEFT JOIN dia_diem dd ON t.id_dia_diem = dd.id
            WHERE 1=1";
    
    if ($location) {
        $location = $conn->real_escape_string($location);
        $sql .= " AND (dd.ten = '$location' OR t.ten LIKE '%$location%')";
    }
    
    if ($tour_type) {
        $tour_type = $conn->real_escape_string($tour_type);
        $sql .= " AND t.loai_tour = '$tour_type'";
    }
    
    if ($duration !== null) {
        $sql .= " AND t.so_ngay = $duration";
    }
    
    if ($price_min >= 0 || $price_max < 999999999) {
        $sql .= " AND t.gia >= $price_min AND t.gia <= $price_max";
    }
    
    $sql .= " ORDER BY t.id DESC";
    
    $result = $conn->query($sql);
    
    if (!$result) {
        throw new Exception("Database error: " . $conn->error);
    }
    
    $tours = [];
    
    while ($row = $result->fetch_assoc()) {
        $url_anh = $row['url_anh_chinh'];
        
        // Xử lý ảnh giống handleGetTours
        if (empty($url_anh)) {
            $url_anh = '/img/default.jpg';
        } else if (strpos($url_anh, '/') !== 0) {
            // Nếu không bắt đầu với '/', thêm '/img/' vào đầu
            $url_anh = '/img/' . $url_anh;
        }
        
        $tour = [
            'id' => $row['id'],
            'name' => $row['ten'],
            'description' => $row['mo_ta'],
            'price' => (int)$row['gia'],
            'duration' => (int)$row['so_ngay'],
            'url_anh_chinh' => $url_anh,
            'rating' => (float)$row['danh_gia'],
            'rating_count' => (int)$row['so_danh_gia'],
            'type' => $row['loai_tour'] ?? '',
            'location' => $row['location'] ?? 'Việt Nam'
        ];
        
        $tours[] = $tour;
    }
    
    echo json_encode([
        'success' => true,
        'data' => $tours,
        'count' => count($tours),
        'filters' => [
            'location' => $location,
            'tour_type' => $tour_type,
            'duration' => $duration,
            'price_min' => $price_min,
            'price_max' => $price_max
        ]
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// =====================================================
// COMBO HANDLERS
// =====================================================

function handleGetCombos() {
    global $conn;
    
    $sql = "SELECT 
                gc.id,
                gc.ten,
                gc.mo_ta,
                gc.gia_goc,
                gc.gia_ban,
                gc.phan_tram_khuyen_mai,
                gc.url_anh,
                gc.loai_combo,
                gc.tien_ich,
                gc.ngay_khoi_hanh,
                dd.ten AS location
            FROM goi_combo gc
            LEFT JOIN dia_diem dd ON gc.id_dia_diem = dd.id
            ORDER BY gc.id DESC";
    
    $result = $conn->query($sql);
    
    if (!$result) {
        throw new Exception("Database error: " . $conn->error);
    }
    
    $combos = [];
    
    while ($row = $result->fetch_assoc()) {
        $combo = [
            'id' => $row['id'],
            'name' => $row['ten'],
            'description' => $row['mo_ta'],
            'original_price' => (int)$row['gia_goc'],
            'price' => (int)$row['gia_ban'],
            'discount_percent' => (int)$row['phan_tram_khuyen_mai'],
            'image' => sanitizeImagePath($row['url_anh']),
            'combo_type' => $row['loai_combo'],
            'tien_ich' => $row['tien_ich'] ?? '',
            'start_date' => $row['ngay_khoi_hanh'] ?? '',
            'location' => $row['location'] ?? 'Việt Nam'
        ];
        
        $combos[] = $combo;
    }
    
    echo json_encode([
        'success' => true,
        'data' => $combos,
        'count' => count($combos)
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function handleGetComboDetail() {
    global $conn;
    
    $combo_id = isset($_GET['id']) ? intval($_GET['id']) : 0;
    
    if (!$combo_id) {
        echo json_encode([
            'success' => false,
            'message' => 'Combo ID không hợp lệ'
        ]);
        exit;
    }
    
    // Get combo information
    $sql = "SELECT gc.*, dd.ten as dia_diem_ten 
            FROM goi_combo gc 
            LEFT JOIN dia_diem dd ON gc.id_dia_diem = dd.id 
            WHERE gc.id = ?";
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi chuẩn bị câu lệnh: ' . $conn->error
        ]);
        exit;
    }
    
    $stmt->bind_param("i", $combo_id);
    if (!$stmt->execute()) {
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi thực thi câu lệnh: ' . $stmt->error
        ]);
        exit;
    }
    
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Combo không tìm thấy'
        ]);
        exit;
    }
    
    $combo = $result->fetch_assoc();
    $stmt->close();
    
    // Cast numeric fields to proper types
    $combo['id'] = (int)$combo['id'];
    $combo['gia_goc'] = (int)$combo['gia_goc'];
    $combo['gia_ban'] = (int)$combo['gia_ban'];
    $combo['phan_tram_khuyen_mai'] = (int)$combo['phan_tram_khuyen_mai'];
    
    // Chuẩn hóa đường dẫn ảnh
    $combo['url_anh'] = sanitizeImagePath($combo['url_anh']);
    
    // Format prices
    $combo['gia_goc_formatted'] = number_format($combo['gia_goc'], 0, ',', '.');
    $combo['gia_ban_formatted'] = number_format($combo['gia_ban'], 0, ',', '.');
    
    // Initialize schedule array
    $combo['schedule'] = [];
    
    // Query lịch trình combo (schedule days)
    $schedule_sql = "SELECT * FROM lich_trinh_tour WHERE id_goi_combo = ? ORDER BY so_ngay ASC";
    $schedule_stmt = $conn->prepare($schedule_sql);
    
    if (!$schedule_stmt) {
        error_log("Combo Schedule Query Prepare Error: " . $conn->error);
        // Continue without schedule data
    } else {
        $schedule_stmt->bind_param("i", $combo_id);
        
        if (!$schedule_stmt->execute()) {
            error_log("Combo Schedule Query Execute Error: " . $schedule_stmt->error);
        } else {
            $schedule_result = $schedule_stmt->get_result();
            
            if ($schedule_result && $schedule_result->num_rows > 0) {
                while ($schedule_row = $schedule_result->fetch_assoc()) {
                    // Get details for this schedule day
                    $schedule_id = (int)$schedule_row['id'];
                    
                    $detail_sql = "SELECT * FROM lich_trinh_chi_tiet WHERE lich_trinh_id = ? ORDER BY id ASC";
                    $detail_stmt = $conn->prepare($detail_sql);
                    
                    $schedule_row['details'] = [];
                    
                    if ($detail_stmt) {
                        $detail_stmt->bind_param("i", $schedule_id);
                        
                        if ($detail_stmt->execute()) {
                            $detail_result = $detail_stmt->get_result();
                            
                            if ($detail_result && $detail_result->num_rows > 0) {
                                while ($detail_row = $detail_result->fetch_assoc()) {
                                    $schedule_row['details'][] = $detail_row;
                                }
                            }
                        } else {
                            error_log("Detail Query Execute Error for schedule_id=$schedule_id: " . $detail_stmt->error);
                        }
                        
                        $detail_stmt->close();
                    } else {
                        error_log("Detail Query Prepare Error: " . $conn->error);
                    }
                    
                    $combo['schedule'][] = $schedule_row;
                }
            }
        }
        
        $schedule_stmt->close();
    }
    
    echo json_encode([
        'success' => true,
        'data' => $combo
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function handleSearchCombos() {
    global $conn;
    
    $location = isset($_GET['location']) && $_GET['location'] != 'Tất cả' && $_GET['location'] != '' ? $_GET['location'] : null;
    $combo_type = isset($_GET['combo_type']) && $_GET['combo_type'] != 'Tất cả' && $_GET['combo_type'] != '' ? $_GET['combo_type'] : null;
    $duration = isset($_GET['duration']) && $_GET['duration'] != 'Tất cả' && $_GET['duration'] != '' ? $_GET['duration'] : null;
    
    // Price filter - chỉ apply nếu người dùng chọn khoảng giá từ dropdown
    $has_price_filter = isset($_GET['price_min']) && isset($_GET['price_max']);
    $price_min = $has_price_filter ? (int)$_GET['price_min'] : 0;
    $price_max = $has_price_filter ? (int)$_GET['price_max'] : 999999999;
    
    $sql = "SELECT 
                gc.id,
                gc.ten,
                gc.mo_ta,
                gc.gia_goc,
                gc.gia_ban,
                gc.phan_tram_khuyen_mai,
                gc.url_anh,
                gc.loai_combo,
                gc.tien_ich,
                gc.ngay_khoi_hanh,
                gc.thoi_gian_combo,
                dd.ten AS location
            FROM goi_combo gc
            LEFT JOIN dia_diem dd ON gc.id_dia_diem = dd.id
            WHERE 1=1";
    
    if ($location) {
        $location = $conn->real_escape_string($location);
        $sql .= " AND (dd.ten = '$location' OR gc.ten LIKE '%$location%')";
    }
    
    if ($combo_type) {
        $combo_type = $conn->real_escape_string($combo_type);
        $sql .= " AND gc.loai_combo = '$combo_type'";
    }
    
    if ($duration) {
        $duration = $conn->real_escape_string($duration);
        $sql .= " AND gc.thoi_gian_combo = '$duration'";
    }
    
    // Chỉ apply price filter nếu user chọn khoảng giá từ dropdown
    if ($has_price_filter) {
        $sql .= " AND gc.gia_ban >= $price_min AND gc.gia_ban <= $price_max";
    }
    
    $sql .= " ORDER BY gc.id DESC";
    
    $result = $conn->query($sql);
    
    if (!$result) {
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $conn->error,
            'data' => [],
            'count' => 0
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $combos = [];
    
    while ($row = $result->fetch_assoc()) {
        $combo = [
            'id' => $row['id'],
            'name' => $row['ten'],
            'description' => $row['mo_ta'],
            'original_price' => (int)$row['gia_goc'],
            'price' => (int)$row['gia_ban'],
            'discount_percent' => (int)$row['phan_tram_khuyen_mai'],
            'image' => sanitizeImagePath($row['url_anh']),
            'combo_type' => $row['loai_combo'],
            'tien_ich' => $row['tien_ich'] ?? '',
            'start_date' => $row['ngay_khoi_hanh'] ?? '',
            'location' => $row['location'] ?? 'Việt Nam'
        ];
        
        $combos[] = $combo;
    }
    
    echo json_encode([
        'success' => true,
        'data' => $combos,
        'count' => count($combos),
        'filters' => [
            'location' => $location,
            'combo_type' => $combo_type,
            'duration' => $duration,
            'price_min' => $price_min,
            'price_max' => $price_max
        ]
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function handleFilterCombos() {
    global $conn;
    
    $location = isset($_GET['location']) && $_GET['location'] != 'Tất cả' && $_GET['location'] != '' ? $_GET['location'] : null;
    $combo_type = isset($_GET['combo_type']) && $_GET['combo_type'] != 'Tất cả' && $_GET['combo_type'] != '' ? $_GET['combo_type'] : null;
    $duration = isset($_GET['duration']) ? $_GET['duration'] : null;
    
    // Price filter - chỉ apply nếu người dùng chọn khoảng giá từ dropdown
    $has_price_filter = isset($_GET['price_min']) && isset($_GET['price_max']);
    $price_min = $has_price_filter ? (int)$_GET['price_min'] : 0;
    $price_max = $has_price_filter ? (int)$_GET['price_max'] : 999999999;
    
    $sql = "SELECT 
                gc.id,
                gc.ten,
                gc.mo_ta,
                gc.gia_goc,
                gc.gia_ban,
                gc.phan_tram_khuyen_mai,
                gc.url_anh,
                gc.loai_combo,
                gc.tien_ich,
                gc.ngay_khoi_hanh,
                gc.thoi_gian_combo,
                dd.ten AS location
            FROM goi_combo gc
            LEFT JOIN dia_diem dd ON gc.id_dia_diem = dd.id
            WHERE 1=1";
    
    if ($location) {
        $location = $conn->real_escape_string($location);
        $sql .= " AND (dd.ten = '$location' OR gc.ten LIKE '%$location%')";
    }
    
    if ($combo_type) {
        $combo_type = $conn->real_escape_string($combo_type);
        $sql .= " AND gc.loai_combo = '$combo_type'";
    }
    
    if ($duration) {
        $duration = $conn->real_escape_string($duration);
        $sql .= " AND gc.thoi_gian_combo = '$duration'";
    }
    
    // Chỉ apply price filter nếu user chọn khoảng giá từ dropdown
    if ($has_price_filter) {
        $sql .= " AND gc.gia_ban >= $price_min AND gc.gia_ban <= $price_max";
    }
    
    $sql .= " ORDER BY gc.id DESC";
    
    $result = $conn->query($sql);
    
    if (!$result) {
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $conn->error,
            'data' => [],
            'count' => 0
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $combos = [];
    
    while ($row = $result->fetch_assoc()) {
        $combo = [
            'id' => $row['id'],
            'name' => $row['ten'],
            'description' => $row['mo_ta'],
            'original_price' => (int)$row['gia_goc'],
            'price' => (int)$row['gia_ban'],
            'discount_percent' => (int)$row['phan_tram_khuyen_mai'],
            'image' => sanitizeImagePath($row['url_anh']),
            'combo_type' => $row['loai_combo'],
            'tien_ich' => $row['tien_ich'] ?? '',
            'start_date' => $row['ngay_khoi_hanh'] ?? '',
            'location' => $row['location'] ?? 'Việt Nam'
        ];
        
        $combos[] = $combo;
    }
    
    echo json_encode([
        'success' => true,
        'data' => $combos,
        'count' => count($combos),
        'filters' => [
            'location' => $location,
            'combo_type' => $combo_type,
            'duration' => $duration,
            'price_min' => $price_min,
            'price_max' => $price_max
        ]
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// =====================================================
// LOCATION & DURATION HANDLERS
// =====================================================

function handleGetLocations() {
    global $conn;
    
    // Get vung_mien filter from query parameters
    $vung_mien = isset($_GET['vung_mien']) ? trim($_GET['vung_mien']) : null;
    
    $sql = "SELECT dd.id, dd.ten, dd.quoc_gia, dd.url_anh, dd.mo_ta, dd.vung_mien, 
                   COUNT(DISTINCT t.id) as tour_count
            FROM dia_diem dd
            LEFT JOIN tour t ON t.id_dia_diem = dd.id AND t.trang_thai = 'Hoạt động'";
    
    if ($vung_mien) {
        $vung_mien = $conn->real_escape_string($vung_mien);
        $sql .= " WHERE dd.vung_mien = '$vung_mien'";
    }
    
    $sql .= " GROUP BY dd.id ORDER BY dd.ten ASC";
    
    $result = $conn->query($sql);
    
    if (!$result) {
        throw new Exception("Lỗi truy vấn: " . $conn->error);
    }
    
    $locations = [];
    
    while ($row = $result->fetch_assoc()) {
        $locations[] = [
            'id' => intval($row['id']),
            'ten' => $row['ten'],
            'quoc_gia' => $row['quoc_gia'],
            'url_anh' => $row['url_anh'],
            'mo_ta' => $row['mo_ta'],
            'vung_mien' => $row['vung_mien'],
            'tour_count' => intval($row['tour_count'])
        ];
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => $locations,
        'count' => count($locations)
    ]);
    exit;
}

function handleGetDurations() {
    global $conn;
    
    $sql = "SELECT DISTINCT t.so_ngay 
            FROM tour t
            WHERE t.trang_thai = 'Hoạt động'
            ORDER BY t.so_ngay ASC";
    
    $result = $conn->query($sql);
    
    if (!$result) {
        throw new Exception("Lỗi truy vấn: " . $conn->error);
    }
    
    $durations = [];
    
    while ($row = $result->fetch_assoc()) {
        $so_ngay = intval($row['so_ngay']);
        $so_dem = $so_ngay - 1;
        
        $durations[] = [
            'so_ngay' => $so_ngay,
            'label' => $so_ngay . ' ngày ' . $so_dem . ' đêm',
            'duration_format' => $so_ngay . 'N' . $so_dem . 'Đ'
        ];
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => $durations,
        'count' => count($durations)
    ]);
    exit;
}

// =====================================================
// FILTER DATA HANDLER
// =====================================================

function handleGetFilterData() {
    global $conn;
    
    $filterType = isset($_GET['type']) ? trim($_GET['type']) : 'tours';
    
    $sql_locations = "SELECT id, ten 
                      FROM dia_diem
                      ORDER BY ten";
    
    $result_locations = $conn->query($sql_locations);
    $locations = [];
    
    if ($result_locations) {
        while ($row = $result_locations->fetch_assoc()) {
            $locations[] = [
                'id' => $row['id'],
                'name' => $row['ten']
            ];
        }
    }
    
    if ($filterType === 'tours' || $filterType === 'all') {
        $sql_tour_types = "SELECT DISTINCT loai_tour FROM tour 
                          WHERE loai_tour IS NOT NULL AND loai_tour != ''
                          ORDER BY loai_tour";
        
        $result_tour_types = $conn->query($sql_tour_types);
        $tour_types = [];
        
        if ($result_tour_types) {
            while ($row = $result_tour_types->fetch_assoc()) {
                $tour_types[] = $row['loai_tour'];
            }
        }
    } else {
        $tour_types = [];
    }
    
    // Lấy durations từ goi_combo (thoi_gian_combo) - lấy các giá trị riêng biệt
    $sql_combo_durations = "SELECT DISTINCT thoi_gian_combo FROM goi_combo 
                           WHERE thoi_gian_combo IS NOT NULL AND thoi_gian_combo != ''
                           ORDER BY 
                               CASE 
                                   WHEN thoi_gian_combo LIKE '1%' THEN 1
                                   WHEN thoi_gian_combo LIKE '2%' THEN 2
                                   WHEN thoi_gian_combo LIKE '3%' THEN 3
                                   WHEN thoi_gian_combo LIKE '4%' THEN 4
                                   WHEN thoi_gian_combo LIKE '5%' THEN 5
                                   ELSE 99
                               END";
    
    $result_combo_durations = $conn->query($sql_combo_durations);
    $combo_durations = [];
    
    if ($result_combo_durations) {
        while ($row = $result_combo_durations->fetch_assoc()) {
            if (!empty($row['thoi_gian_combo'])) {
                $combo_durations[] = [
                    'value' => trim($row['thoi_gian_combo']),
                    'label' => trim($row['thoi_gian_combo'])
                ];
            }
        }
    }
    
    // Lấy durations từ tour (so_ngay) - các giá trị số
    $sql_durations = "SELECT DISTINCT so_ngay FROM tour 
                      WHERE so_ngay IS NOT NULL AND so_ngay > 0
                      ORDER BY so_ngay";
    
    $result_durations = $conn->query($sql_durations);
    $durations = [];
    
    if ($result_durations) {
        while ($row = $result_durations->fetch_assoc()) {
            $days = (int)$row['so_ngay'];
            $nights = max(0, $days - 1);
            
            // Chỉ hiển thị số đêm nếu > 0
            if ($nights > 0) {
                $label = $days . ' ngày ' . $nights . ' đêm';
            } else {
                $label = $days . ' ngày';
            }
            
            $durations[] = [
                'value' => $days,
                'label' => $label
            ];
        }
    }
    
    // Nếu là combo, dùng combo_durations thay vì tour durations
    if ($filterType === 'combos') {
        $durations = $combo_durations;
    }
    
    if ($filterType === 'combos' || $filterType === 'all') {
        $sql_combo_types = "SELECT DISTINCT loai_combo FROM goi_combo 
                          WHERE loai_combo IS NOT NULL AND loai_combo != ''
                          ORDER BY loai_combo";
        
        $result_combo_types = $conn->query($sql_combo_types);
        $combo_types = [];
        
        if ($result_combo_types) {
            while ($row = $result_combo_types->fetch_assoc()) {
                $combo_types[] = $row['loai_combo'];
            }
        }
    } else {
        $combo_types = [];
    }
    
    $price_ranges = [
        ['label' => 'Dưới 3 triệu', 'min' => 0, 'max' => 3000000],
        ['label' => '3 - 5 triệu', 'min' => 3000000, 'max' => 5000000],
        ['label' => '5 - 10 triệu', 'min' => 5000000, 'max' => 10000000],
        ['label' => 'Trên 10 triệu', 'min' => 10000000, 'max' => 999999999]
    ];
    
    $response = [
        'success' => true,
        'data' => [
            'locations' => $locations,
            'price_ranges' => $price_ranges
        ]
    ];
    
    if ($filterType === 'tours' || $filterType === 'all') {
        $response['data']['tour_types'] = $tour_types;
        $response['data']['durations'] = $durations;
    }
    
    if ($filterType === 'combos' || $filterType === 'all') {
        $response['data']['combo_types'] = $combo_types;
        // Thêm durations cho combos
        $response['data']['durations'] = $durations;
    }
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    exit;
}

// =====================================================
// FAVORITE/WISHLIST FUNCTIONS
// =====================================================

function handleToggleFavorite() {
    global $conn;
    
    $id_tour = isset($_GET['id_tour']) ? intval($_GET['id_tour']) : 0;
    $id_nguoi_dung = isset($_GET['id_nguoi_dung']) ? intval($_GET['id_nguoi_dung']) : 0;
    
    if (!$id_tour || !$id_nguoi_dung) {
        echo json_encode([
            'success' => false,
            'message' => 'Thiếu thông tin tour hoặc người dùng'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Check if favorite already exists
    $checkSql = "SELECT id FROM yeu_thich 
                 WHERE id_nguoi_dung = ? AND id_tour = ? AND id_goi_combo IS NULL";
    $checkStmt = $conn->prepare($checkSql);
    $checkStmt->bind_param("ii", $id_nguoi_dung, $id_tour);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult && $checkResult->num_rows > 0) {
        // Already favorited - remove it
        $deleteSql = "DELETE FROM yeu_thich 
                      WHERE id_nguoi_dung = ? AND id_tour = ? AND id_goi_combo IS NULL";
        $deleteStmt = $conn->prepare($deleteSql);
        $deleteStmt->bind_param("ii", $id_nguoi_dung, $id_tour);
        
        if ($deleteStmt->execute()) {
            $deleteStmt->close();
            echo json_encode([
                'success' => true,
                'isFavorited' => false,
                'message' => 'Đã xóa khỏi yêu thích'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Lỗi xóa yêu thích: ' . $conn->error
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
    } else {
        // Not favorited - add it
        $insertSql = "INSERT INTO yeu_thich (id_nguoi_dung, id_tour, ngay_them) 
                      VALUES (?, ?, CURRENT_TIMESTAMP)";
        $insertStmt = $conn->prepare($insertSql);
        $insertStmt->bind_param("ii", $id_nguoi_dung, $id_tour);
        
        if ($insertStmt->execute()) {
            $favorite_id = $insertStmt->insert_id;
            $insertStmt->close();
            $checkStmt->close();
            
            echo json_encode([
                'success' => true,
                'isFavorited' => true,
                'id' => $favorite_id,
                'message' => 'Đã thêm vào yêu thích'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Lỗi thêm yêu thích: ' . $conn->error
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
    }
}

// Create favorite WITH group (for tours)
function handleCreateFavoriteWithGroup() {
    global $conn;
    
    $data = json_decode(file_get_contents('php://input'), true);
    $id_tour = intval($data['id_tour'] ?? 0);
    $id_nguoi_dung = intval($data['id_nguoi_dung'] ?? 0);
    $id_nhom = intval($data['id_nhom'] ?? 0);
    
    if (!$id_tour || !$id_nguoi_dung || !$id_nhom) {
        echo json_encode([
            'success' => false,
            'message' => 'Thiếu thông tin bắt buộc'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $sql = "INSERT INTO yeu_thich (id_nguoi_dung, id_tour, id_nhom, ngay_them) 
            VALUES (?, ?, ?, CURRENT_TIMESTAMP)";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $conn->error
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $stmt->bind_param("iii", $id_nguoi_dung, $id_tour, $id_nhom);
    
    if ($stmt->execute()) {
        $favorite_id = $stmt->insert_id;
        $stmt->close();
        echo json_encode([
            'success' => true,
            'id' => $favorite_id,
            'message' => 'Đã thêm vào nhóm yêu thích'
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $conn->error
        ], JSON_UNESCAPED_UNICODE);
    }
    exit;
}

// Create combo favorite WITH group (for combos)
function handleCreateComboFavoriteWithGroup() {
    global $conn;
    
    $data = json_decode(file_get_contents('php://input'), true);
    $id_goi_combo = intval($data['id_goi_combo'] ?? 0);
    $id_nguoi_dung = intval($data['id_nguoi_dung'] ?? 0);
    $id_nhom = intval($data['id_nhom'] ?? 0);
    
    if (!$id_goi_combo || !$id_nguoi_dung || !$id_nhom) {
        echo json_encode([
            'success' => false,
            'message' => 'Thiếu thông tin bắt buộc'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $sql = "INSERT INTO yeu_thich (id_nguoi_dung, id_goi_combo, id_nhom, ngay_them) 
            VALUES (?, ?, ?, CURRENT_TIMESTAMP)";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $conn->error
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $stmt->bind_param("iii", $id_nguoi_dung, $id_goi_combo, $id_nhom);
    
    if ($stmt->execute()) {
        $favorite_id = $stmt->insert_id;
        $stmt->close();
        echo json_encode([
            'success' => true,
            'id' => $favorite_id,
            'message' => 'Đã thêm vào nhóm yêu thích'
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $conn->error
        ], JSON_UNESCAPED_UNICODE);
    }
    exit;
}

function handleCheckFavorite() {
    global $conn;
    
    $id_tour = isset($_GET['id_tour']) ? intval($_GET['id_tour']) : 0;
    $id_nguoi_dung = isset($_GET['id_nguoi_dung']) ? intval($_GET['id_nguoi_dung']) : 0;
    
    if (!$id_tour || !$id_nguoi_dung) {
        echo json_encode([
            'success' => false,
            'message' => 'Thiếu thông tin tour hoặc người dùng',
            'isFavorited' => false
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $sql = "SELECT id FROM yeu_thich 
            WHERE id_nguoi_dung = $id_nguoi_dung AND id_tour = $id_tour AND id_goi_combo IS NULL
            LIMIT 1";
    
    $result = $conn->query($sql);
    
    if ($result && $result->num_rows > 0) {
        // Already in favorites
        echo json_encode([
            'success' => true,
            'isFavorited' => true
        ], JSON_UNESCAPED_UNICODE);
    } else {
        // Not in favorites
        echo json_encode([
            'success' => true,
            'isFavorited' => false
        ], JSON_UNESCAPED_UNICODE);
    }
    exit;
}

// =====================================================
// COMBO FAVORITE/WISHLIST FUNCTIONS
// =====================================================

function handleToggleComboFavorite() {
    global $conn;
    
    // Check if user is logged in
    session_start();
    if (!isset($_SESSION['user_id']) || empty($_SESSION['user_id'])) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Vui lòng đăng nhập để thêm vào yêu thích'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $id_goi_combo = isset($_GET['id_goi_combo']) ? intval($_GET['id_goi_combo']) : 0;
    $id_nguoi_dung = isset($_GET['id_nguoi_dung']) ? intval($_GET['id_nguoi_dung']) : 0;
    
    // Verify user ID from session matches the request
    if ($id_nguoi_dung != $_SESSION['user_id']) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Không có quyền thực hiện hành động này'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    if (!$id_goi_combo || !$id_nguoi_dung) {
        echo json_encode([
            'success' => false,
            'message' => 'Thiếu thông tin combo hoặc người dùng'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Check if favorite already exists
    $checkSql = "SELECT id FROM yeu_thich 
                 WHERE id_nguoi_dung = ? AND id_goi_combo = ?";
    $checkStmt = $conn->prepare($checkSql);
    $checkStmt->bind_param("ii", $id_nguoi_dung, $id_goi_combo);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult && $checkResult->num_rows > 0) {
        // Already favorited - remove it
        $deleteSql = "DELETE FROM yeu_thich 
                      WHERE id_nguoi_dung = ? AND id_goi_combo = ?";
        $deleteStmt = $conn->prepare($deleteSql);
        $deleteStmt->bind_param("ii", $id_nguoi_dung, $id_goi_combo);
        
        if ($deleteStmt->execute()) {
            $deleteStmt->close();
            echo json_encode([
                'success' => true,
                'isFavorited' => false,
                'message' => 'Đã xóa khỏi yêu thích'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Lỗi xóa yêu thích: ' . $conn->error
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
    } else {
        // Not favorited - add it
        $insertSql = "INSERT INTO yeu_thich (id_nguoi_dung, id_goi_combo, ngay_them) 
                      VALUES (?, ?, CURRENT_TIMESTAMP)";
        $insertStmt = $conn->prepare($insertSql);
        $insertStmt->bind_param("ii", $id_nguoi_dung, $id_goi_combo);
        
        if ($insertStmt->execute()) {
            $favorite_id = $insertStmt->insert_id;
            $insertStmt->close();
            $checkStmt->close();
            
            echo json_encode([
                'success' => true,
                'isFavorited' => true,
                'id' => $favorite_id,
                'message' => 'Đã thêm vào yêu thích'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Lỗi thêm yêu thích: ' . $conn->error
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
    }
}

function handleCheckComboFavorite() {
    global $conn;
    
    // Check if user is logged in
    session_start();
    if (!isset($_SESSION['user_id']) || empty($_SESSION['user_id'])) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Vui lòng đăng nhập để kiểm tra yêu thích',
            'isFavorited' => false
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $id_goi_combo = isset($_GET['id_goi_combo']) ? intval($_GET['id_goi_combo']) : 0;
    $id_nguoi_dung = isset($_GET['id_nguoi_dung']) ? intval($_GET['id_nguoi_dung']) : 0;
    
    // Verify user ID from session matches the request
    if ($id_nguoi_dung != $_SESSION['user_id']) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Không có quyền thực hiện hành động này',
            'isFavorited' => false
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    if (!$id_goi_combo || !$id_nguoi_dung) {
        echo json_encode([
            'success' => false,
            'message' => 'Thiếu thông tin combo hoặc người dùng',
            'isFavorited' => false
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $sql = "SELECT id FROM yeu_thich 
            WHERE id_nguoi_dung = $id_nguoi_dung AND id_goi_combo = $id_goi_combo
            LIMIT 1";
    
    $result = $conn->query($sql);
    
    if ($result && $result->num_rows > 0) {
        // Already in favorites
        echo json_encode([
            'success' => true,
            'isFavorited' => true
        ], JSON_UNESCAPED_UNICODE);
    } else {
        // Not in favorites
        echo json_encode([
            'success' => true,
            'isFavorited' => false
        ], JSON_UNESCAPED_UNICODE);
    }
    exit;
}

// =====================================================
// REMOVE COMBO FAVORITE
// =====================================================

function handleRemoveComboFavorite() {
    global $conn;
    
    // Check if user is logged in
    session_start();
    if (!isset($_SESSION['user_id']) || empty($_SESSION['user_id'])) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Vui lòng đăng nhập để bỏ yêu thích'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $id_goi_combo = isset($_GET['id_goi_combo']) ? intval($_GET['id_goi_combo']) : 0;
    $id_nguoi_dung = isset($_GET['id_nguoi_dung']) ? intval($_GET['id_nguoi_dung']) : 0;
    
    // Verify user ID from session matches the request
    if ($id_nguoi_dung != $_SESSION['user_id']) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Không có quyền thực hiện hành động này'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    if (!$id_goi_combo || !$id_nguoi_dung) {
        echo json_encode([
            'success' => false,
            'message' => 'Thiếu thông tin combo hoặc người dùng'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Delete from favorites
    $sql = "DELETE FROM yeu_thich 
            WHERE id_nguoi_dung = $id_nguoi_dung AND id_goi_combo = $id_goi_combo";
    
    if ($conn->query($sql)) {
        echo json_encode([
            'success' => true
        ], JSON_UNESCAPED_UNICODE);
    } else {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi khi xoá yêu thích: ' . $conn->error
        ], JSON_UNESCAPED_UNICODE);
    }
    exit;
}

// =====================================================
// FAVORITES GROUP MANAGEMENT
// =====================================================

function handleGetFavoriteGroups() {
    global $conn;
    
    $id_nguoi_dung = isset($_GET['id_nguoi_dung']) ? intval($_GET['id_nguoi_dung']) : 0;
    
    if (!$id_nguoi_dung) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'groups' => [],
            'message' => 'Thiếu ID người dùng'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    try {
        // First check if table exists
        $checkTableSQL = "SHOW TABLES LIKE 'nhom_yeuthich'";
        $checkResult = $conn->query($checkTableSQL);
        
        if (!$checkResult || $checkResult->num_rows === 0) {
            throw new Exception("Bảng nhom_yeuthich không tồn tại");
        }
        
        // Check table structure
        $describeSQL = "DESCRIBE nhom_yeuthich";
        $describeResult = $conn->query($describeSQL);
        
        if (!$describeResult) {
            throw new Exception("Không thể kiểm tra cấu trúc bảng: " . $conn->error);
        }
        
        $sql = "SELECT id, ten_nhom, ngay_tao FROM nhom_yeuthich 
                WHERE id_nguoi_dung = ? 
                ORDER BY ngay_tao DESC";
        
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param("i", $id_nguoi_dung);
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $result = $stmt->get_result();
        
        $groups = [];
        while ($row = $result->fetch_assoc()) {
            // Rename ten_nhom to ten for frontend compatibility
            $row['ten'] = $row['ten_nhom'];
            unset($row['ten_nhom']);
            
            // Count items in each group
            $countSql = "SELECT COUNT(*) as total FROM yeu_thich WHERE id_nhom = ?";
            $countStmt = $conn->prepare($countSql);
            if ($countStmt) {
                $countStmt->bind_param("i", $row['id']);
                $countStmt->execute();
                $countResult = $countStmt->get_result();
                $countRow = $countResult->fetch_assoc();
                $row['so_tour'] = intval($countRow['total']);
                $countStmt->close();
            } else {
                $row['so_tour'] = 0;
            }
            
            $groups[] = $row;
        }
        
        $stmt->close();
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'groups' => $groups
        ], JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'groups' => [],
            'message' => 'Lỗi: ' . $e->getMessage(),
            'debug' => $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
        error_log("handleGetFavoriteGroups error: " . $e->getMessage());
    }
    exit;
}

function handleCreateFavoriteGroup() {
    global $conn;
    
    $inputData = file_get_contents('php://input');
    $data = json_decode($inputData, true);
    
    $id_nguoi_dung = isset($data['id_nguoi_dung']) ? intval($data['id_nguoi_dung']) : 0;
    $ten = isset($data['ten']) ? trim($data['ten']) : '';
    
    if (!$id_nguoi_dung || !$ten) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Tên nhóm không được để trống'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    try {
        $sql = "INSERT INTO nhom_yeuthich (id_nguoi_dung, ten_nhom, ngay_tao) 
                VALUES (?, ?, CURRENT_TIMESTAMP)";
        
        $stmt = $conn->prepare($sql);
        
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param("is", $id_nguoi_dung, $ten);
        
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $group_id = $stmt->insert_id;
        $stmt->close();
        
        http_response_code(201);
        echo json_encode([
            'success' => true,
            'group_id' => $group_id,
            'message' => 'Tạo nhóm thành công'
        ], JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi tạo nhóm: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
        error_log("handleCreateFavoriteGroup error: " . $e->getMessage());
    }
    exit;
}

function handleGetUserFavorites() {
    global $conn;
    
    $id_nguoi_dung = isset($_GET['id_nguoi_dung']) ? intval($_GET['id_nguoi_dung']) : 0;
    $id_nhom = isset($_GET['id_nhom']) ? intval($_GET['id_nhom']) : 0;
    
    if (!$id_nguoi_dung) {
        echo json_encode([
            'success' => false,
            'favorites' => [],
            'message' => 'Thiếu ID người dùng'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Get favorites with group filter if provided
    $sql = "SELECT y.id, y.id_tour, y.id_goi_combo, y.id_nhom, y.ngay_them,
                   t.id as tour_id, t.ten as tour_ten, t.gia, t.url_anh_chinh,
                   gc.id as combo_id, gc.ten as combo_ten, gc.gia_ban
            FROM yeu_thich y
            LEFT JOIN tour t ON y.id_tour = t.id
            LEFT JOIN goi_combo gc ON y.id_goi_combo = gc.id
            WHERE y.id_nguoi_dung = ?";
    
    if ($id_nhom > 0) {
        $sql .= " AND y.id_nhom = ?";
    }
    
    $sql .= " ORDER BY y.ngay_them DESC";
    
    $stmt = $conn->prepare($sql);
    
    if ($id_nhom > 0) {
        $stmt->bind_param("ii", $id_nguoi_dung, $id_nhom);
    } else {
        $stmt->bind_param("i", $id_nguoi_dung);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $favorites = [];
    while ($row = $result->fetch_assoc()) {
        $fav = [
            'id' => intval($row['id']),
            'id_nhom' => $row['id_nhom'] ? intval($row['id_nhom']) : null,
            'ngay_them' => $row['ngay_them']
        ];
        
        if ($row['id_tour']) {
            $fav['type'] = 'tour';
            $fav['id_tour'] = intval($row['id_tour']);
            $fav['ten'] = $row['tour_ten'];
            $fav['gia'] = floatval($row['gia']);
            $fav['url_anh'] = $row['url_anh_chinh'];
        } else {
            $fav['type'] = 'combo';
            $fav['id_combo'] = intval($row['combo_id']);
            $fav['ten'] = $row['combo_ten'];
            $fav['gia'] = floatval($row['gia_ban']);
            $fav['url_anh'] = $row['url_anh'] ?? '';
        }
        
        $favorites[] = $fav;
    }
    
    $stmt->close();
    
    echo json_encode([
        'success' => true,
        'favorites' => $favorites
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function handleAddToFavoriteGroup() {
    global $conn;
    
    $inputData = file_get_contents('php://input');
    $data = json_decode($inputData, true);
    
    $id_yeu_thich = isset($data['id_yeu_thich']) ? intval($data['id_yeu_thich']) : 0;
    $id_nhom = isset($data['id_nhom']) ? intval($data['id_nhom']) : 0;
    
    if (!$id_yeu_thich || !$id_nhom) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Thiếu thông tin cần thiết'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    try {
        $sql = "UPDATE yeu_thich SET id_nhom = ? WHERE id = ?";
        
        $stmt = $conn->prepare($sql);
        
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param("ii", $id_nhom, $id_yeu_thich);
        
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $stmt->close();
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Thêm vào nhóm thành công'
        ], JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi cập nhật: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
        error_log("handleAddToFavoriteGroup error: " . $e->getMessage());
    }
    exit;
}

function handleInitFavoriteTables() {
    global $conn;
    
    $messages = [];
    
    try {
        // Check if nhom_yeuthich table exists
        $checkTableSQL = "SHOW TABLES LIKE 'nhom_yeuthich'";
        $tableResult = $conn->query($checkTableSQL);
        
        if (!$tableResult || $tableResult->num_rows === 0) {
            // Table doesn't exist, create it
            $createTableSQL = "CREATE TABLE nhom_yeuthich (
                id INT AUTO_INCREMENT PRIMARY KEY,
                id_nguoi_dung INT NOT NULL,
                ten_nhom VARCHAR(100) NOT NULL,
                ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (id_nguoi_dung) REFERENCES nguoi_dung(id) ON DELETE CASCADE
            )";
            
            if ($conn->query($createTableSQL)) {
                $messages[] = "✅ Bảng nhom_yeuthich tạo thành công";
            } else {
                $messages[] = "⚠️ Bảng nhom_yeuthich: " . $conn->error;
            }
        } else {
            // Table exists, check if it has correct columns
            $describeSQL = "SHOW COLUMNS FROM nhom_yeuthich LIKE 'ten_nhom'";
            $colResult = $conn->query($describeSQL);
            
            if (!$colResult || $colResult->num_rows === 0) {
                // Wrong schema, need to drop and recreate
                $conn->query("SET FOREIGN_KEY_CHECKS=0");
                $conn->query("DROP TABLE nhom_yeuthich");
                $conn->query("SET FOREIGN_KEY_CHECKS=1");
                
                $createTableSQL = "CREATE TABLE nhom_yeuthich (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    id_nguoi_dung INT NOT NULL,
                    ten_nhom VARCHAR(100) NOT NULL,
                    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (id_nguoi_dung) REFERENCES nguoi_dung(id) ON DELETE CASCADE
                )";
                
                if ($conn->query($createTableSQL)) {
                    $messages[] = "✅ Bảng nhom_yeuthich được tạo lại với schema đúng";
                } else {
                    $messages[] = "⚠️ Lỗi tạo lại bảng: " . $conn->error;
                }
            } else {
                $messages[] = "ℹ️ Bảng nhom_yeuthich đã tồn tại với schema đúng";
            }
        }
        
        // Check if id_nhom column exists
        $checkSQL = "SHOW COLUMNS FROM yeu_thich LIKE 'id_nhom'";
        $result = $conn->query($checkSQL);
        
        if (!$result || $result->num_rows === 0) {
            // Disable FK checks to alter yeu_thich table
            $conn->query("SET FOREIGN_KEY_CHECKS=0");
            
            // Add column
            $addColSQL = "ALTER TABLE yeu_thich ADD COLUMN id_nhom INT NULL AFTER id_goi_combo";
            if ($conn->query($addColSQL)) {
                $messages[] = "✅ Cột id_nhom được thêm vào bảng yeu_thich";
            } else {
                $messages[] = "⚠️ Thêm cột id_nhom: " . $conn->error;
            }
            
            // Add foreign key
            $addFKSQL = "ALTER TABLE yeu_thich ADD FOREIGN KEY (id_nhom) REFERENCES nhom_yeuthich(id) ON DELETE SET NULL";
            if ($conn->query($addFKSQL)) {
                $messages[] = "✅ Foreign key thêm thành công";
            } else {
                $messages[] = "⚠️ Foreign key: " . $conn->error;
            }
            
            // Re-enable foreign key checks
            $conn->query("SET FOREIGN_KEY_CHECKS=1");
        } else {
            $messages[] = "ℹ️ Cột id_nhom đã tồn tại";
        }
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'messages' => $messages
        ], JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
    }
    exit;
}

// =====================================================
// GET FAVORITES BY GROUP
// =====================================================

function handleGetFavoritesByGroup() {
    global $conn;
    
    $id_nguoi_dung = isset($_GET['id_nguoi_dung']) ? intval($_GET['id_nguoi_dung']) : 0;
    $id_nhom = isset($_GET['id_nhom']) ? intval($_GET['id_nhom']) : 0;
    
    if (!$id_nguoi_dung || !$id_nhom) {
        echo json_encode([
            'success' => false,
            'favorites' => [],
            'message' => 'Thiếu ID người dùng hoặc ID nhóm'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Get favorites in group with tour/combo details
    $sql = "SELECT y.id, y.id_tour, y.id_goi_combo, y.id_nhom, y.ngay_them
            FROM yeu_thich y
            WHERE y.id_nguoi_dung = ? AND y.id_nhom = ?
            ORDER BY y.ngay_them DESC";
    
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi chuẩn bị truy vấn: ' . $conn->error
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $stmt->bind_param("ii", $id_nguoi_dung, $id_nhom);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $favorites = [];
    while ($row = $result->fetch_assoc()) {
        $favorites[] = [
            'id' => intval($row['id']),
            'id_tour' => $row['id_tour'] ? intval($row['id_tour']) : null,
            'id_goi_combo' => $row['id_goi_combo'] ? intval($row['id_goi_combo']) : null,
            'id_nhom' => intval($row['id_nhom']),
            'ngay_them' => $row['ngay_them']
        ];
    }
    
    $stmt->close();
    
    echo json_encode([
        'success' => true,
        'favorites' => $favorites
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// =====================================================
// DELETE FAVORITE GROUP
// =====================================================

function handleDeleteFavoriteGroup() {
    global $conn;
    
    $inputData = file_get_contents('php://input');
    $data = json_decode($inputData, true);
    
    $id_nhom = isset($data['id_nhom']) ? intval($data['id_nhom']) : 0;
    $id_nguoi_dung = isset($data['id_nguoi_dung']) ? intval($data['id_nguoi_dung']) : 0;
    
    if (!$id_nhom || !$id_nguoi_dung) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Thiếu thông tin cần thiết'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    try {
        // First delete all favorites in this group
        $deleteFavSQL = "DELETE FROM yeu_thich WHERE id_nhom = ? AND id_nguoi_dung IN (SELECT ? UNION SELECT id FROM nguoi_dung WHERE id = ?)";
        
        // Simpler approach - just delete favorites with this group ID
        $deleteFavSQL = "DELETE FROM yeu_thich WHERE id_nhom = ?";
        $stmt = $conn->prepare($deleteFavSQL);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("i", $id_nhom);
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        $stmt->close();
        
        // Then delete the group itself
        $deleteGroupSQL = "DELETE FROM nhom_yeuthich WHERE id = ? AND id_nguoi_dung = ?";
        $stmt = $conn->prepare($deleteGroupSQL);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("ii", $id_nhom, $id_nguoi_dung);
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        $stmt->close();
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Xóa nhóm thành công'
        ], JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi xóa nhóm: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
        error_log("handleDeleteFavoriteGroup error: " . $e->getMessage());
    }
    exit;
}

// =====================================================
// REMOVE TOUR FROM GROUP
// =====================================================

function handleRemoveTourFromGroup() {
    global $conn;
    
    $inputData = file_get_contents('php://input');
    $data = json_decode($inputData, true);
    
    $id_nhom = isset($data['id_nhom']) ? intval($data['id_nhom']) : 0;
    $id_tour = isset($data['id_tour']) ? intval($data['id_tour']) : 0;
    $id_nguoi_dung = isset($data['id_nguoi_dung']) ? intval($data['id_nguoi_dung']) : 0;
    
    if (!$id_nhom || !$id_tour || !$id_nguoi_dung) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Thiếu thông tin cần thiết'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    try {
        // Delete favorite
        $deleteSQL = "DELETE FROM yeu_thich WHERE id_nhom = ? AND id_tour = ? AND id_nguoi_dung = ?";
        
        $stmt = $conn->prepare($deleteSQL);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param("iii", $id_nhom, $id_tour, $id_nguoi_dung);
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        
        $stmt->close();
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Xóa tour khỏi nhóm thành công'
        ], JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi xóa tour: ' . $e->getMessage()
        ], JSON_UNESCAPED_UNICODE);
        error_log("handleRemoveTourFromGroup error: " . $e->getMessage());
    }
    exit;
}

// =====================================================
// UPDATE PROFILE API (alternate endpoint)
// =====================================================

function handleUpdateProfileAPI() {
    global $conn;
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'message' => 'Phương thức không được phép. Vui lòng sử dụng POST.'
        ]);
        exit;
    }
    
    // Check for avatar upload
    if (isset($_POST['action']) && $_POST['action'] === 'update_avatar') {
        authUpdateAvatar();
    } elseif (isset($_POST['action']) && $_POST['action'] === 'update_profile_with_avatar') {
        authUpdateProfileWithAvatar();
    } else {
        authUpdateProfile();
    }
}

// =====================================================
// BOOKING HANDLER - Lưu đặt tour vào bảng dat_tour
// =====================================================

function handleCreateBooking() {
    global $conn;
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'message' => 'Phương thức không được phép. Vui lòng sử dụng POST.'
        ]);
        exit;
    }
    
    // Get JSON input
    $inputData = file_get_contents('php://input');
    $data = json_decode($inputData, true);
    
    if ($data === null) {
        throw new Exception('Dữ liệu JSON không hợp lệ');
    }
    
    // Validate required fields
    $id_nguoi_dung = isset($data['id_nguoi_dung']) ? intval($data['id_nguoi_dung']) : 0;
    $id_tour = isset($data['id_tour']) && $data['id_tour'] !== null ? intval($data['id_tour']) : null;
    $id_goi_combo = isset($data['id_goi_combo']) && $data['id_goi_combo'] !== null ? intval($data['id_goi_combo']) : null;
    $so_nguoi_lon = isset($data['so_nguoi_lon']) ? intval($data['so_nguoi_lon']) : 1;
    $so_tre_em = isset($data['so_tre_em']) ? intval($data['so_tre_em']) : 0;
    $ngay_khoi_hanh = isset($data['ngay_khoi_hanh']) ? trim($data['ngay_khoi_hanh']) : '';
    
    // FIX: Kiểm tra phuong_thuc_thanh_toan cẩn thận - không dùng trim sẽ rỗng
    $phuong_thuc_thanh_toan = isset($data['phuong_thuc_thanh_toan']) && !empty($data['phuong_thuc_thanh_toan']) 
        ? trim($data['phuong_thuc_thanh_toan']) 
        : 'Chuyển khoản';
    
    $tong_tien = isset($data['tong_tien']) ? floatval($data['tong_tien']) : 0;
    $ghi_chu = isset($data['ghi_chu']) ? trim($data['ghi_chu']) : null;
    
    // Debug logging
    error_log('=== BOOKING DATA RECEIVED ===');
    error_log('id_nguoi_dung: ' . $id_nguoi_dung);
    error_log('id_tour: ' . var_export($id_tour, true));
    error_log('id_goi_combo: ' . var_export($id_goi_combo, true));
    error_log('phuong_thuc_thanh_toan: ' . var_export($phuong_thuc_thanh_toan, true) . ' (length: ' . strlen($phuong_thuc_thanh_toan) . ')');
    error_log('so_nguoi_lon: ' . $so_nguoi_lon);
    error_log('ngay_khoi_hanh: ' . $ngay_khoi_hanh);
    error_log('tong_tien: ' . $tong_tien);
    error_log('Full JSON Data: ' . var_export($data, true));
    error_log('=====================');
    
    
    // Validation
    if ($id_nguoi_dung <= 0) {
        throw new Exception('ID người dùng không hợp lệ');
    }
    
    // Either id_tour or id_goi_combo must be provided, but not both NULL
    if (($id_tour === null || $id_tour <= 0) && ($id_goi_combo === null || $id_goi_combo <= 0)) {
        throw new Exception('Vui lòng chọn tour hoặc combo');
    }
    
    if ($so_nguoi_lon <= 0) {
        throw new Exception('Số người lớn phải lớn hơn 0');
    }
    
    if ($so_tre_em < 0) {
        throw new Exception('Số trẻ em không hợp lệ');
    }
    
    if (empty($ngay_khoi_hanh)) {
        throw new Exception('Ngày khởi hành là bắt buộc');
    }
    
    // Validate date format
    $date_obj = DateTime::createFromFormat('Y-m-d', $ngay_khoi_hanh);
    if (!$date_obj) {
        throw new Exception('Định dạng ngày không hợp lệ. Vui lòng sử dụng định dạng YYYY-MM-DD');
    }
    
    // Check if user exists
    $checkUserSql = "SELECT id FROM nguoi_dung WHERE id = ?";
    $checkUserStmt = $conn->prepare($checkUserSql);
    if (!$checkUserStmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    $checkUserStmt->bind_param("i", $id_nguoi_dung);
    $checkUserStmt->execute();
    $checkUserResult = $checkUserStmt->get_result();
    
    if ($checkUserResult->num_rows === 0) {
        throw new Exception('Người dùng không tồn tại');
    }
    $checkUserStmt->close();
    
    // Check if tour exists (if id_tour is provided)
    if ($id_tour && $id_tour > 0) {
        $checkTourSql = "SELECT id FROM tour WHERE id = ?";
        $checkTourStmt = $conn->prepare($checkTourSql);
        if (!$checkTourStmt) {
            throw new Exception("Lỗi prepare statement: " . $conn->error);
        }
        
        $checkTourStmt->bind_param("i", $id_tour);
        $checkTourStmt->execute();
        $checkTourResult = $checkTourStmt->get_result();
        
        if ($checkTourResult->num_rows === 0) {
            throw new Exception('Tour không tồn tại');
        }
        $checkTourStmt->close();
    }
    
    // Check if combo exists (if id_goi_combo is provided)
    if ($id_goi_combo && $id_goi_combo > 0) {
        $checkComboSql = "SELECT id FROM goi_combo WHERE id = ?";
        $checkComboStmt = $conn->prepare($checkComboSql);
        if (!$checkComboStmt) {
            throw new Exception("Lỗi prepare statement: " . $conn->error);
        }
        
        $checkComboStmt->bind_param("i", $id_goi_combo);
        $checkComboStmt->execute();
        $checkComboResult = $checkComboStmt->get_result();
        
        if ($checkComboResult->num_rows === 0) {
            throw new Exception('Combo không tồn tại');
        }
        $checkComboStmt->close();
    }
    
    // Generate unique booking code: BOOK-{userID}-{timestamp}
    $so_dat_tour = 'BOOK-' . $id_nguoi_dung . '-' . time();
    
    // Default status and ensure ghi_chu is string
    $trang_thai = 'Chờ xác nhận';
    $ghi_chu = $ghi_chu ?? '';
    
    // Handle NULL values properly - keep NULL as NULL
    $id_tour_final = ($id_tour && $id_tour > 0) ? $id_tour : null;
    $id_goi_combo_final = ($id_goi_combo && $id_goi_combo > 0) ? $id_goi_combo : null;
    
    // Insert into dat_tour table - DON'T use IF() in SQL, handle NULL in PHP
    $insertSql = "INSERT INTO dat_tour (
                    so_dat_tour,
                    id_nguoi_dung, 
                    id_tour, 
                    id_goi_combo,
                    so_nguoi_lon, 
                    so_tre_em, 
                    ngay_khoi_hanh, 
                    phuong_thuc_thanh_toan, 
                    tong_tien, 
                    ghi_chu, 
                    trang_thai,
                    ngay_tao
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";
    
    $insertStmt = $conn->prepare($insertSql);
    if (!$insertStmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }
    
    // Correct bind_param types:
    // s = string, i = int, d = double/float
    // Order: so_dat_tour(s), id_nguoi_dung(i), id_tour(i), id_goi_combo(i), so_nguoi_lon(i), so_tre_em(i),
    //        ngay_khoi_hanh(s), phuong_thuc_thanh_toan(s), tong_tien(d), ghi_chu(s), trang_thai(s)
    $insertStmt->bind_param(
        "siiiiissdss",
        $so_dat_tour,
        $id_nguoi_dung,
        $id_tour_final,
        $id_goi_combo_final,
        $so_nguoi_lon,
        $so_tre_em,
        $ngay_khoi_hanh,
        $phuong_thuc_thanh_toan,
        $tong_tien,
        $ghi_chu,
        $trang_thai
    );
    
    if (!$insertStmt->execute()) {
        throw new Exception("Lỗi khi lưu dữ liệu: " . $insertStmt->error);
    }
    
    $booking_id = $insertStmt->insert_id;
    $insertStmt->close();
    
    monitorTrackEvent('booking_created', [
        'booking_id' => $booking_id,
        'tour_id' => $id_tour ?? $id_goi_combo,
        'user_id' => $id_nguoi_dung,
        'total' => $tong_tien,
        'payment_method' => $phuong_thuc_thanh_toan
    ], [
        'total_amount' => $tong_tien,
        'adults' => $so_nguoi_lon,
        'children' => $so_tre_em
    ]);

    // Return success response
    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Đặt tour thành công! Đơn đặt tour của bạn đã được ghi nhận. Chúng tôi sẽ liên hệ xác nhận trong thời gian sớm nhất.',
        'so_dat_tour' => $so_dat_tour,
        'booking_id' => $booking_id,
        'booking_data' => [
            'id_so_dat_tour' => $booking_id,
            'id_nguoi_dung' => $id_nguoi_dung,
            'id_tour' => $id_tour,
            'id_goi_combo' => $id_goi_combo,
            'so_nguoi_lon' => $so_nguoi_lon,
            'so_tre_em' => $so_tre_em,
            'ngay_khoi_hanh' => $ngay_khoi_hanh,
            'phuong_thuc_thanh_toan' => $phuong_thuc_thanh_toan,
            'tong_tien' => $tong_tien,
            'trang_thai' => $trang_thai
        ]
    ]);
    exit;
}

// =====================================================
// GET BOOKED TOURS HANDLER
// =====================================================

function handleGetBookedTours() {
    global $conn;
    
    try {
        // Get user ID from request
        $id_nguoi_dung = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
        
        error_log('=== GET_BOOKED_TOURS ===');
        error_log('user_id: ' . $id_nguoi_dung);
        
        if ($id_nguoi_dung <= 0) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'ID người dùng không hợp lệ. Vui lòng chỉ định user_id.'
            ]);
            exit;
        }
        
        // Verify user exists
        $checkUserSql = "SELECT id FROM nguoi_dung WHERE id = ?";
        $checkUserStmt = $conn->prepare($checkUserSql);
        
        if (!$checkUserStmt) {
            throw new Exception("Lỗi prepare statement: " . $conn->error);
        }
        
        $checkUserStmt->bind_param("i", $id_nguoi_dung);
        $checkUserStmt->execute();
        $checkUserResult = $checkUserStmt->get_result();
        
        if ($checkUserResult->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Người dùng không tồn tại'
            ]);
            exit;
        }
        $checkUserStmt->close();
        
        // Get booked tours and combos - UNION both types
        // Part 1: Tours
        $sql = "SELECT 
                    dt.id as booking_id,
                    dt.so_dat_tour,
                    dt.ngay_khoi_hanh,
                    dt.so_nguoi_lon,
                    dt.so_tre_em,
                    dt.tong_tien,
                    dt.trang_thai,
                    dt.ngay_tao,
                    t.id as tour_id,
                    0 as combo_id,
                    t.ten as tour_name,
                    t.mo_ta,
                    t.gia,
                    t.so_ngay,
                    t.so_nguoi_toi_da,
                    t.url_anh_chinh,
                    t.danh_gia,
                    t.so_danh_gia,
                    dd.ten as dia_diem_ten,
                    dd.quoc_gia,
                    'tour' as item_type
                FROM dat_tour dt
                INNER JOIN tour t ON dt.id_tour = t.id
                LEFT JOIN dia_diem dd ON t.id_dia_diem = dd.id
                WHERE dt.id_nguoi_dung = ? AND dt.id_tour > 0
                
                UNION ALL
                
                SELECT 
                    dt.id as booking_id,
                    dt.so_dat_tour,
                    dt.ngay_khoi_hanh,
                    dt.so_nguoi_lon,
                    dt.so_tre_em,
                    dt.tong_tien,
                    dt.trang_thai,
                    dt.ngay_tao,
                    0 as tour_id,
                    gc.id as combo_id,
                    gc.ten as tour_name,
                    gc.mo_ta,
                    gc.gia_ban as gia,
                    CASE 
                        WHEN gc.thoi_gian_combo = '2N1D' THEN 2
                        WHEN gc.thoi_gian_combo = '3N2D' THEN 3
                        WHEN gc.thoi_gian_combo = '4N3D' THEN 4
                        WHEN gc.thoi_gian_combo = '5N4D' THEN 5
                        ELSE 2
                    END as so_ngay,
                    99 as so_nguoi_toi_da,
                    gc.url_anh as url_anh_chinh,
                    0 as danh_gia,
                    0 as so_danh_gia,
                    gc.loai_combo as dia_diem_ten,
                    'Việt Nam' as quoc_gia,
                    'combo' as item_type
                FROM dat_tour dt
                INNER JOIN goi_combo gc ON dt.id_goi_combo = gc.id
                WHERE dt.id_nguoi_dung = ? AND dt.id_goi_combo > 0
                
                ORDER BY ngay_tao DESC";
        
        error_log('SQL Query (Union Tours + Combos): ' . $sql);
        
        $stmt = $conn->prepare($sql);
        
        if (!$stmt) {
            throw new Exception("Lỗi prepare statement: " . $conn->error);
        }
        
        $stmt->bind_param("ii", $id_nguoi_dung, $id_nguoi_dung);
        
        if (!$stmt->execute()) {
            throw new Exception("Lỗi thực thi query: " . $stmt->error);
        }
        
        $result = $stmt->get_result();
        $bookings = [];
        
        while ($row = $result->fetch_assoc()) {
            // Determine trip status based on ngay_khoi_hanh - Compare DATE ONLY (not time)
            $departure_date_str = $row['ngay_khoi_hanh'];
            $today_date_str = date('Y-m-d');
            
            // Extract ONLY the date part (YYYY-MM-DD) - ignore any time component
            $departure_date_only = substr($departure_date_str, 0, 10);  // Get first 10 chars: YYYY-MM-DD
            
            // Parse as dates using DateTime for more reliable comparison
            $today_date = new DateTime($today_date_str);
            $tour_start_date_obj = new DateTime($departure_date_only);
            $tour_duration_days = intval($row['so_ngay']);
            
            // Calculate end date
            $tour_end_date_obj = clone $tour_start_date_obj;
            $tour_end_date_obj->add(new DateInterval('P' . ($tour_duration_days - 1) . 'D'));
            
            // Compare dates
            if ($today_date < $tour_start_date_obj) {
                $trip_status = 'upcoming';
            } elseif ($today_date >= $tour_start_date_obj && $today_date <= $tour_end_date_obj) {
                $trip_status = 'ongoing';
            } else {
                $trip_status = 'completed';
            }
            
            error_log("🔍 Trip Status Debug: departure={$departure_date_only}, today={$today_date_str}, duration={$tour_duration_days}N, end_date=" . $tour_end_date_obj->format('Y-m-d') . ", status={$trip_status}");
            
            // Format price
            $url_anh = $row['url_anh_chinh'];
            if (!empty($url_anh) && strpos($url_anh, '/') !== 0 && strpos($url_anh, 'http') === false) {
                $url_anh = '/img/' . $url_anh;
            }
            
            $location = '';
            if (!empty($row['dia_diem_ten'])) {
                $location = $row['dia_diem_ten'];
                if (!empty($row['quoc_gia'])) {
                    $location .= ', ' . $row['quoc_gia'];
                }
            }
            
            // Check if user has already reviewed this tour/combo
            $has_reviewed = false;
            if (intval($row['tour_id']) > 0) {
                $reviewCheckSql = "SELECT COUNT(*) as count FROM danh_gia WHERE id_nguoi_dung = ? AND id_tour = ?";
                $reviewCheckStmt = $conn->prepare($reviewCheckSql);
                $reviewCheckStmt->bind_param("ii", $id_nguoi_dung, $row['tour_id']);
                $reviewCheckStmt->execute();
                $reviewCheckResult = $reviewCheckStmt->get_result();
                $reviewCheckRow = $reviewCheckResult->fetch_assoc();
                $reviewCheckStmt->close();
                $has_reviewed = $reviewCheckRow['count'] > 0;
            } elseif (intval($row['combo_id']) > 0) {
                $reviewCheckSql = "SELECT COUNT(*) as count FROM danh_gia WHERE id_nguoi_dung = ? AND id_goi_combo = ?";
                $reviewCheckStmt = $conn->prepare($reviewCheckSql);
                $reviewCheckStmt->bind_param("ii", $id_nguoi_dung, $row['combo_id']);
                $reviewCheckStmt->execute();
                $reviewCheckResult = $reviewCheckStmt->get_result();
                $reviewCheckRow = $reviewCheckResult->fetch_assoc();
                $reviewCheckStmt->close();
                $has_reviewed = $reviewCheckRow['count'] > 0;
            }
            
            $bookings[] = [
                'booking_id' => intval($row['booking_id']),
                'so_dat_tour' => $row['so_dat_tour'],
                'tour_id' => intval($row['tour_id']),
                'combo_id' => intval($row['combo_id']),
                'tour_name' => $row['tour_name'],
                'tour_description' => $row['mo_ta'],
                'tour_price' => floatval($row['gia']),
                'tour_duration' => intval($row['so_ngay']),
                'tour_image' => $url_anh,
                'location' => $location,
                'departure_date' => $row['ngay_khoi_hanh'],
                'num_adults' => intval($row['so_nguoi_lon']),
                'num_children' => intval($row['so_tre_em']),
                'total_amount' => floatval($row['tong_tien']),
                'booking_status' => $row['trang_thai'],
                'booking_date' => $row['ngay_tao'],
                'trip_status' => $trip_status,
                'duration_text' => intval($row['so_ngay']) . 'N' . (intval($row['so_ngay']) - 1) . 'Đ',
                'item_type' => $row['item_type'],
                'has_reviewed' => $has_reviewed
            ];
        }
        
        $stmt->close();
        
        error_log('Bookings found: ' . count($bookings));
        error_log('===================');
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'data' => $bookings,
            'count' => count($bookings),
            'message' => count($bookings) > 0 ? 'Lấy danh sách chuyến đi thành công' : 'Chưa có chuyến đi nào'
        ]);
        exit;
    } catch (Exception $e) {
        error_log('❌ handleGetBookedTours Error: ' . $e->getMessage());
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $e->getMessage()
        ]);
        exit;
    }
}

// =====================================================
// GET BOOKING DETAIL HANDLER
// =====================================================

function handleGetBookingDetail() {
    global $conn;
    
    try {
        $booking_id = isset($_GET['booking_id']) ? intval($_GET['booking_id']) : 0;
        
        if ($booking_id <= 0) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'ID đặt tour không hợp lệ. Vui lòng chỉ định booking_id.'
            ]);
            exit;
        }
        
        // Get booking details with related data - Handle both TOUR and COMBO bookings
        $sql = "SELECT 
                    dt.id as booking_id,
                    dt.so_dat_tour,
                    dt.id_nguoi_dung,
                    dt.id_tour,
                    dt.id_goi_combo,
                    dt.ngay_khoi_hanh,
                    dt.so_nguoi_lon,
                    dt.so_tre_em,
                    dt.tong_tien,
                    dt.trang_thai,
                    dt.ngay_tao,
                    dt.ghi_chu,
                    
                    -- Tour fields (when id_tour > 0)
                    COALESCE(t.id, 0) as tour_id,
                    COALESCE(t.ten, gc.ten) as tour_name,
                    COALESCE(t.mo_ta, gc.mo_ta) as mo_ta,
                    COALESCE(t.gia, gc.gia_ban) as gia,
                    CASE 
                        WHEN dt.id_tour > 0 THEN COALESCE(t.so_ngay, 2)
                        WHEN dt.id_goi_combo > 0 THEN 
                            CASE 
                                WHEN gc.thoi_gian_combo = '2N1D' THEN 2
                                WHEN gc.thoi_gian_combo = '3N2D' THEN 3
                                WHEN gc.thoi_gian_combo = '4N3D' THEN 4
                                WHEN gc.thoi_gian_combo = '5N4D' THEN 5
                                ELSE 2
                            END
                        ELSE 2
                    END as so_ngay,
                    COALESCE(t.so_nguoi_toi_da, 99) as so_nguoi_toi_da,
                    COALESCE(t.url_anh_chinh, gc.url_anh) as url_anh_chinh,
                    COALESCE(t.danh_gia, 0) as danh_gia,
                    COALESCE(t.so_danh_gia, 0) as so_danh_gia,
                    
                    -- Location
                    dd.ten as dia_diem_ten,
                    dd.quoc_gia,
                    
                    -- Combo fields
                    COALESCE(gc.id, 0) as combo_id,
                    gc.ten as goi_combo_ten,
                    gc.tien_ich as combo_amenities,
                    gc.loai_combo,
                    
                    -- Customer details
                    nd.email as user_email,
                    
                    -- Item type (tour or combo)
                    CASE WHEN dt.id_tour > 0 THEN 'tour' ELSE 'combo' END as item_type
                FROM dat_tour dt
                LEFT JOIN tour t ON dt.id_tour = t.id AND dt.id_tour > 0
                LEFT JOIN goi_combo gc ON dt.id_goi_combo = gc.id AND dt.id_goi_combo > 0
                LEFT JOIN dia_diem dd ON t.id_dia_diem = dd.id
                INNER JOIN nguoi_dung nd ON dt.id_nguoi_dung = nd.id
                WHERE dt.id = ?";
        
        $stmt = $conn->prepare($sql);
        
        if (!$stmt) {
            throw new Exception("Lỗi prepare statement: " . $conn->error);
        }
        
        $stmt->bind_param("i", $booking_id);
        
        if (!$stmt->execute()) {
            throw new Exception("Lỗi thực thi query: " . $stmt->error);
        }
        
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Không tìm thấy thông tin đặt tour'
            ]);
            $stmt->close();
            exit;
        }
        
        $row = $result->fetch_assoc();
        $stmt->close();
        
        // Check if booking exists (has either tour OR combo)
        if (intval($row['tour_id']) === 0 && intval($row['combo_id']) === 0) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Không tìm thấy thông tin tour/combo cho đặt tour này'
            ]);
            exit;
        }
        
        // Determine trip status
        $departure_date_str = $row['ngay_khoi_hanh'];
        $today_date_str = date('Y-m-d');
        $departure_date_only = substr($departure_date_str, 0, 10);
        
        $today_date = new DateTime($today_date_str);
        $tour_start_date_obj = new DateTime($departure_date_only);
        $tour_duration_days = intval($row['so_ngay']);
        
        $tour_end_date_obj = clone $tour_start_date_obj;
        $tour_end_date_obj->add(new DateInterval('P' . ($tour_duration_days - 1) . 'D'));
        
        if ($today_date < $tour_start_date_obj) {
            $trip_status = 'upcoming';
            $can_cancel = true;
        } elseif ($today_date >= $tour_start_date_obj && $today_date <= $tour_end_date_obj) {
            $trip_status = 'ongoing';
            $can_cancel = false;
        } else {
            $trip_status = 'completed';
            $can_cancel = false;
        }
        
        // Format image
        $url_anh = $row['url_anh_chinh'];
        if (!empty($url_anh) && strpos($url_anh, '/') !== 0 && strpos($url_anh, 'http') === false) {
            $url_anh = '/img/' . $url_anh;
        }
        
        $location = '';
        if (!empty($row['dia_diem_ten'])) {
            $location = $row['dia_diem_ten'];
            if (!empty($row['quoc_gia'])) {
                $location .= ', ' . $row['quoc_gia'];
            }
        }
        
        // Check if user has already reviewed this tour/combo
        $has_reviewed = false;
        $id_nguoi_dung = $row['id_nguoi_dung'];
        if (intval($row['tour_id']) > 0) {
            $reviewCheckSql = "SELECT COUNT(*) as count FROM danh_gia WHERE id_nguoi_dung = ? AND id_tour = ?";
            $reviewCheckStmt = $conn->prepare($reviewCheckSql);
            $reviewCheckStmt->bind_param("ii", $id_nguoi_dung, $row['tour_id']);
            $reviewCheckStmt->execute();
            $reviewCheckResult = $reviewCheckStmt->get_result();
            $reviewCheckRow = $reviewCheckResult->fetch_assoc();
            $reviewCheckStmt->close();
            $has_reviewed = $reviewCheckRow['count'] > 0;
        } elseif (intval($row['combo_id']) > 0) {
            $reviewCheckSql = "SELECT COUNT(*) as count FROM danh_gia WHERE id_nguoi_dung = ? AND id_goi_combo = ?";
            $reviewCheckStmt = $conn->prepare($reviewCheckSql);
            $reviewCheckStmt->bind_param("ii", $id_nguoi_dung, $row['combo_id']);
            $reviewCheckStmt->execute();
            $reviewCheckResult = $reviewCheckStmt->get_result();
            $reviewCheckRow = $reviewCheckResult->fetch_assoc();
            $reviewCheckStmt->close();
            $has_reviewed = $reviewCheckRow['count'] > 0;
        }
        
        // Build response
        $booking_detail = [
            'booking_id' => intval($row['booking_id']),
            'so_dat_tour' => $row['so_dat_tour'],
            'trip_status' => $trip_status,
            'can_cancel' => $can_cancel,
            'booking_status' => $row['trang_thai'],
            'booking_date' => $row['ngay_tao'],
            'customer_notes' => $row['ghi_chu'],
            'item_type' => $row['item_type'],
            
            // Tour/Combo details
            'tour_id' => intval($row['tour_id']),
            'combo_id' => intval($row['combo_id']),
            'tour_name' => $row['tour_name'],
            'tour_description' => $row['mo_ta'],
            'tour_price' => floatval($row['gia']),
            'tour_duration' => intval($row['so_ngay']),
            'tour_image' => $url_anh,
            'tour_rating' => floatval($row['danh_gia']),
            'tour_reviews' => intval($row['so_danh_gia']),
            'tour_max_people' => intval($row['so_nguoi_toi_da']),
            'location' => $location,
            
            // Combo-specific details
            'combo_name' => $row['goi_combo_ten'],
            'combo_amenities' => $row['combo_amenities'],
            'combo_type' => $row['loai_combo'],
            
            // Booking details
            'departure_date' => $row['ngay_khoi_hanh'],
            'num_adults' => intval($row['so_nguoi_lon']),
            'num_children' => intval($row['so_tre_em']),
            'total_people' => intval($row['so_nguoi_lon']) + intval($row['so_tre_em']),
            'total_amount' => floatval($row['tong_tien']),
            
            // Customer details
            'customer_email' => $row['user_email'],
            
            'duration_text' => intval($row['so_ngay']) . 'N' . (intval($row['so_ngay']) - 1) . 'Đ',
            'has_reviewed' => $has_reviewed
        ];
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'data' => $booking_detail,
            'message' => 'Lấy chi tiết đặt tour thành công'
        ]);
        exit;
    } catch (Exception $e) {
        error_log('❌ handleGetBookingDetail Error: ' . $e->getMessage());
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $e->getMessage()
        ]);
        exit;
    }
}

// =====================================================
// CANCEL BOOKING HANDLER
// =====================================================

function handleCancelBooking() {
    global $conn;
    
    try {
        $booking_id = isset($_POST['booking_id']) ? intval($_POST['booking_id']) : 0;
        $reason = isset($_POST['reason']) ? trim($_POST['reason']) : 'Người dùng yêu cầu hủy';
        
        if ($booking_id <= 0) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'ID đặt tour không hợp lệ. Vui lòng chỉ định booking_id.'
            ]);
            exit;
        }
        
        // Get booking details first
        $selectSql = "SELECT dt.id, dt.id_nguoi_dung, dt.trang_thai, dt.ngay_khoi_hanh, t.so_ngay
                     FROM dat_tour dt
                     INNER JOIN tour t ON dt.id_tour = t.id
                     WHERE dt.id = ?";
        
        $stmt = $conn->prepare($selectSql);
        if (!$stmt) {
            throw new Exception("Lỗi prepare statement: " . $conn->error);
        }
        
        $stmt->bind_param("i", $booking_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Không tìm thấy thông tin đặt tour'
            ]);
            $stmt->close();
            exit;
        }
        
        $row = $result->fetch_assoc();
        $stmt->close();
        
        // Check if booking can be cancelled
        $tour_start_date = strtotime($row['ngay_khoi_hanh']);
        $today = time();
        
        if ($today >= $tour_start_date) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Không thể hủy chuyến đi này vì tour đã bắt đầu hoặc đã hoàn thành'
            ]);
            exit;
        }
        
        // Update booking status to cancelled - waiting for confirmation
        $updateSql = "UPDATE dat_tour SET trang_thai = 'Chờ Xác Nhận Hủy', ghi_chu = ? WHERE id = ?";
        $updateStmt = $conn->prepare($updateSql);
        
        if (!$updateStmt) {
            throw new Exception("Lỗi prepare statement: " . $conn->error);
        }
        
        $cancelReason = "Hủy bởi người dùng: " . $reason;
        $updateStmt->bind_param("si", $cancelReason, $booking_id);
        
        if (!$updateStmt->execute()) {
            throw new Exception("Lỗi cập nhật: " . $updateStmt->error);
        }
        
        $updateStmt->close();
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Yêu cầu hủy tour đã được ghi nhận. Chúng tôi sẽ xử lý hoàn tiền trong vòng 3-5 ngày làm việc.',
            'data' => [
                'booking_id' => $booking_id,
                'new_status' => 'Chờ Xác Nhận Hủy'
            ]
        ]);
        exit;
    } catch (Exception $e) {
        error_log('❌ handleCancelBooking Error: ' . $e->getMessage());
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $e->getMessage()
        ]);
        exit;
    }
}

// =====================================================
// GET INVOICE HANDLER
// =====================================================

function handleGetInvoice() {
    global $conn;
    
    try {
        $booking_id = isset($_GET['booking_id']) ? intval($_GET['booking_id']) : 0;
        
        if ($booking_id <= 0) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'ID đặt tour không hợp lệ. Vui lòng chỉ định booking_id.'
            ]);
            exit;
        }
        
        // Get booking and payment details
        $sql = "SELECT 
                    dt.id as booking_id,
                    dt.so_dat_tour,
                    dt.ngay_khoi_hanh,
                    dt.so_nguoi_lon,
                    dt.so_tre_em,
                    dt.tong_tien,
                    dt.trang_thai,
                    dt.ngay_tao,
                    t.ten as tour_name,
                    t.gia as tour_price,
                    t.so_ngay
                FROM dat_tour dt
                INNER JOIN tour t ON dt.id_tour = t.id
                WHERE dt.id = ?";
        
        $stmt = $conn->prepare($sql);
        
        if (!$stmt) {
            throw new Exception("Lỗi prepare statement: " . $conn->error);
        }
        
        $stmt->bind_param("i", $booking_id);
        
        if (!$stmt->execute()) {
            throw new Exception("Lỗi thực thi query: " . $stmt->error);
        }
        
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Không tìm thấy thông tin hóa đơn'
            ]);
            $stmt->close();
            exit;
        }
        
        $row = $result->fetch_assoc();
        $stmt->close();
        
        // Determine payment status based on booking status
        $booking_status = $row['trang_thai'];
        if ($booking_status === 'Đã xác nhận') {
            $payment_status = 'Đã xác nhận';
        } elseif ($booking_status === 'Da huy' || $booking_status === 'Chờ Xác Nhận Hủy') {
            $payment_status = 'Đã hủy';
        } else {
            // Default for "Chờ xác nhận" and new bookings
            $payment_status = 'Chờ xử lý';
        }
        
        // Calculate pricing details
        $num_people = intval($row['so_nguoi_lon']) + intval($row['so_tre_em']);
        $price_per_person = floatval($row['tour_price']);
        $subtotal = $price_per_person * $num_people;
        $total = floatval($row['tong_tien']);
        
        // Build response
        $invoice_data = [
            'booking_id' => intval($row['booking_id']),
            'so_dat_tour' => $row['so_dat_tour'],
            'booking_date' => $row['ngay_tao'],
            'booking_status' => $row['trang_thai'],
            
            // Tour details
            'tour_name' => $row['tour_name'],
            'tour_duration' => intval($row['so_ngay']),
            'tour_price_per_person' => floatval($row['tour_price']),
            
            // Passenger details
            'num_adults' => intval($row['so_nguoi_lon']),
            'num_children' => intval($row['so_tre_em']),
            'total_people' => $num_people,
            'departure_date' => $row['ngay_khoi_hanh'],
            
            // Payment details
            'subtotal' => $subtotal,
            'total_amount' => $total,
            'payment_status' => $payment_status
        ];
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'data' => $invoice_data,
            'message' => 'Lấy thông tin hóa đơn thành công'
        ]);
        exit;
    } catch (Exception $e) {
        error_log('❌ handleGetInvoice Error: ' . $e->getMessage());
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $e->getMessage()
        ]);
        exit;
    }
}

// =====================================================
// GET REVIEWS HANDLER
// =====================================================

function handleGetReviews() {
    global $conn;
    
    try {
        $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 3;
        
        // JOIN với bảng nguoi_dung để lấy tên khách hàng, ảnh đại diện - sử dụng đúng tên cột
        $sql = "SELECT 
                    dg.id, 
                    dg.id_nguoi_dung, 
                    dg.so_sao, 
                    dg.binh_luan, 
                    dg.ngay_tao,
                    CONCAT(COALESCE(nd.ten_cuoi, ''), ' ', COALESCE(nd.ten_dau, '')) as ho_ten,
                    nd.so_dien_thoai,
                    nd.anh_dai_dien
                FROM danh_gia dg
                LEFT JOIN nguoi_dung nd ON dg.id_nguoi_dung = nd.id
                ORDER BY dg.id DESC
                LIMIT " . $limit;
        
        $result = $conn->query($sql);
        
        if (!$result) {
            throw new Exception("Query error: " . $conn->error);
        }
        
        $reviews = [];
        
        while ($row = $result->fetch_assoc()) {
            $stars = str_repeat('★', intval($row['so_sao'])) . str_repeat('☆', 5 - intval($row['so_sao']));
            
            // Get customer name
            $ho_ten = trim($row['ho_ten']);
            if (empty($ho_ten) || $ho_ten === ' ') {
                $ho_ten = 'Khách hàng';
            }
            
            // Extract city from phone (placeholder - luôn Việt Nam)
            $thanh_pho = 'Việt Nam';
            
            $tagsPool = ['Tour tuyệt vời', 'HDV chuyên nghiệp', 'Dịch vụ tốt', 'Cảnh đẹp', 'Ẩm thực ngon', 'Khách sạn tốt', 'Giá hợp lý', 'Sắp xếp tốt'];
            $tags = array_slice($tagsPool, rand(0, max(0, count($tagsPool)-3)), 3);
            
            // Get avatar - use from database or fallback to default
            $anh_dai_dien = $row['anh_dai_dien'] ?? '';
            if (empty($anh_dai_dien)) {
                $anh_dai_dien = '/img/default-avatar.jpg';
            }
            
            $reviews[] = [
                'id' => intval($row['id']),
                'ho_ten' => htmlspecialchars($ho_ten),
                'thanh_pho' => $thanh_pho,
                'so_sao' => intval($row['so_sao']),
                'diem_so_format' => intval($row['so_sao']) . '.0',
                'noi_dung' => htmlspecialchars($row['binh_luan'] ?? 'Đánh giá tuyệt vời'),
                'stars' => $stars,
                'tags' => $tags,
                'anh_dai_dien' => $anh_dai_dien,
                'ngay_tao' => $row['ngay_tao']
            ];
        }
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'data' => $reviews,
            'count' => count($reviews)
        ]);
        exit;
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ]);
        exit;
    }
}

// Get all reviews with tour info for TATCA_DANHGIA page - With Pagination
function handleGetAllReviews() {
    global $conn;
    
    try {
        $reviewsPerPage = 9;
        $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
        if ($page < 1) $page = 1;
        
        $offset = ($page - 1) * $reviewsPerPage;
        
        // Get total count
        $countSql = "SELECT COUNT(*) as total FROM danh_gia";
        $countResult = $conn->query($countSql);
        $countRow = $countResult->fetch_assoc();
        $totalReviews = $countRow['total'];
        $totalPages = ceil($totalReviews / $reviewsPerPage);
        
        // JOIN với bảng tour để lấy tên tour - WITH PAGINATION
        $sql = "SELECT 
                    dg.id, 
                    dg.id_nguoi_dung, 
                    dg.id_tour,
                    dg.so_sao, 
                    dg.binh_luan, 
                    dg.ngay_tao,
                    CONCAT(COALESCE(nd.ten_cuoi, ''), ' ', COALESCE(nd.ten_dau, '')) as ho_ten,
                    nd.anh_dai_dien,
                    t.ten as tour_name,
                    dd.ten as dia_diem_ten,
                    dd.quoc_gia
                FROM danh_gia dg
                LEFT JOIN nguoi_dung nd ON dg.id_nguoi_dung = nd.id
                LEFT JOIN tour t ON dg.id_tour = t.id
                LEFT JOIN dia_diem dd ON t.id_dia_diem = dd.id
                ORDER BY dg.id DESC
                LIMIT " . $reviewsPerPage . " OFFSET " . $offset;
        
        $result = $conn->query($sql);
        
        if (!$result) {
            throw new Exception("Query error: " . $conn->error);
        }
        
        $reviews = [];
        
        while ($row = $result->fetch_assoc()) {
            $stars = str_repeat('★', intval($row['so_sao'])) . str_repeat('☆', 5 - intval($row['so_sao']));
            
            // Get customer name
            $ho_ten = trim($row['ho_ten']);
            if (empty($ho_ten) || $ho_ten === ' ') {
                $ho_ten = 'Khách hàng';
            }
            
            // Get tour name
            $tour_name = $row['tour_name'] ?? 'Tour du lịch';
            
            // Get location
            $location = '';
            if (!empty($row['dia_diem_ten'])) {
                $location = $row['dia_diem_ten'];
                if (!empty($row['quoc_gia'])) {
                    $location .= ', ' . $row['quoc_gia'];
                }
            } else {
                $location = 'Việt Nam';
            }
            
            // Get avatar
            $anh_dai_dien = $row['anh_dai_dien'] ?? '';
            if (empty($anh_dai_dien)) {
                $anh_dai_dien = '/img/default-avatar.jpg';
            }
            
            $tagsPool = ['Tour tuyệt vời', 'HDV chuyên nghiệp', 'Dịch vụ tốt', 'Cảnh đẹp', 'Ẩm thực ngon', 'Khách sạn tốt', 'Giá hợp lý', 'Sắp xếp tốt'];
            $tags = array_slice($tagsPool, rand(0, max(0, count($tagsPool)-3)), 3);
            
            $reviews[] = [
                'id' => intval($row['id']),
                'ho_ten' => htmlspecialchars($ho_ten),
                'so_sao' => intval($row['so_sao']),
                'diem_so_format' => intval($row['so_sao']) . '.0',
                'noi_dung' => htmlspecialchars($row['binh_luan'] ?? 'Đánh giá tuyệt vời'),
                'stars' => $stars,
                'tags' => $tags,
                'anh_dai_dien' => $anh_dai_dien,
                'tour_name' => htmlspecialchars($tour_name),
                'location' => htmlspecialchars($location),
                'ngay_tao' => $row['ngay_tao']
            ];
        }
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'data' => $reviews,
            'count' => count($reviews),
            'currentPage' => $page,
            'totalPages' => $totalPages,
            'totalReviews' => $totalReviews
        ]);
        exit;
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ]);
        exit;
    }
}

// =====================================================
// CREATE REVIEW - Tạo đánh giá mới
// =====================================================

function handleCreateReview() {
    global $conn;
    
    try {
        // Get user ID from JWT or session
        $id_nguoi_dung = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
        
        // If not provided, try to get from JWT
        if ($id_nguoi_dung === 0) {
            $token = isset($_COOKIE['token']) ? $_COOKIE['token'] : (isset($_SERVER['HTTP_AUTHORIZATION']) ? str_replace('Bearer ', '', $_SERVER['HTTP_AUTHORIZATION']) : null);
            if ($token) {
                $payload = json_decode(base64_decode(explode('.', $token)[1]), true);
                $id_nguoi_dung = intval($payload['user_id'] ?? 0);
            }
        }
        
        $tour_id = isset($_POST['tour_id']) ? intval($_POST['tour_id']) : 0;
        $combo_id = isset($_POST['combo_id']) ? intval($_POST['combo_id']) : 0;
        $rating = isset($_POST['rating']) ? intval($_POST['rating']) : 0;
        $comment = isset($_POST['comment']) ? trim($_POST['comment']) : '';
        
        error_log("🔍 DEBUG handleCreateReview: POST data = " . json_encode($_POST));
        error_log("🔍 DEBUG: tour_id={$tour_id}, combo_id={$combo_id}, rating={$rating}, comment={$comment}");
        
        if ($id_nguoi_dung <= 0) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'User không hợp lệ']);
            exit;
        }
        
        // Must have either tour_id or combo_id
        if ($tour_id <= 0 && $combo_id <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Tour hoặc Combo không hợp lệ']);
            exit;
        }
        
        if ($rating < 1 || $rating > 5) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Rating phải từ 1-5']);
            exit;
        }
        
        if (empty($comment)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Bình luận không được để trống']);
            exit;
        }
        
        
        if ($tour_id > 0 && $combo_id > 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Chỉ được gửi tour hoặc combo, không cả hai']);
            exit;
        } elseif ($tour_id > 0) {
            // For tours
            $checkBookingSql = "SELECT COUNT(*) as count FROM dat_tour WHERE id_nguoi_dung = ? AND id_tour = ? AND id_tour > 0";
            $checkBookingStmt = $conn->prepare($checkBookingSql);
            $checkBookingStmt->bind_param("ii", $id_nguoi_dung, $tour_id);
            $checkBookingStmt->execute();
            $checkBookingResult = $checkBookingStmt->get_result();
            $bookingRow = $checkBookingResult->fetch_assoc();
            $checkBookingStmt->close();
            
            if ($bookingRow['count'] === 0) {
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => 'Bạn chưa đặt tour này']);
                exit;
            }
            
            // Check if already reviewed
            $checkReviewSql = "SELECT id FROM danh_gia WHERE id_nguoi_dung = ? AND id_tour = ?";
            $checkReviewStmt = $conn->prepare($checkReviewSql);
            $checkReviewStmt->bind_param("ii", $id_nguoi_dung, $tour_id);
            $checkReviewStmt->execute();
            $checkReviewResult = $checkReviewStmt->get_result();
            
            if ($checkReviewResult->num_rows > 0) {
                // Update existing review
                $updateSql = "UPDATE danh_gia SET so_sao = ?, binh_luan = ?, ngay_tao = NOW() WHERE id_nguoi_dung = ? AND id_tour = ?";
                $updateStmt = $conn->prepare($updateSql);
                $updateStmt->bind_param("isii", $rating, $comment, $id_nguoi_dung, $tour_id);
                $updateStmt->execute();
                $updateStmt->close();
            } else {
                // Create new review for tour
                $insertSql = "INSERT INTO danh_gia (id_nguoi_dung, id_tour, id_goi_combo, so_sao, binh_luan, ngay_tao) VALUES (?, ?, NULL, ?, ?, NOW())";
                $insertStmt = $conn->prepare($insertSql);
                
                if (!$insertStmt) {
                    throw new Exception("Lỗi prepare statement: " . $conn->error);
                }
                
                $insertStmt->bind_param("iiss", $id_nguoi_dung, $tour_id, $rating, $comment);
                
                if (!$insertStmt->execute()) {
                    throw new Exception("Lỗi thực thi query: " . $insertStmt->error);
                }
                
                $insertStmt->close();
            }
            
            $checkReviewStmt->close();
        } elseif ($combo_id > 0) {
            // For combos
            $checkBookingSql = "SELECT COUNT(*) as count FROM dat_tour WHERE id_nguoi_dung = ? AND id_goi_combo = ? AND id_goi_combo > 0";
            $checkBookingStmt = $conn->prepare($checkBookingSql);
            $checkBookingStmt->bind_param("ii", $id_nguoi_dung, $combo_id);
            $checkBookingStmt->execute();
            $checkBookingResult = $checkBookingStmt->get_result();
            $bookingRow = $checkBookingResult->fetch_assoc();
            $checkBookingStmt->close();
            
            if ($bookingRow['count'] === 0) {
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => 'Bạn chưa đặt combo này']);
                exit;
            }
            
            // Check if already reviewed
            $checkReviewSql = "SELECT id FROM danh_gia WHERE id_nguoi_dung = ? AND id_goi_combo = ?";
            $checkReviewStmt = $conn->prepare($checkReviewSql);
            $checkReviewStmt->bind_param("ii", $id_nguoi_dung, $combo_id);
            $checkReviewStmt->execute();
            $checkReviewResult = $checkReviewStmt->get_result();
            
            if ($checkReviewResult->num_rows > 0) {
                // Update existing review
                $updateSql = "UPDATE danh_gia SET so_sao = ?, binh_luan = ?, ngay_tao = NOW() WHERE id_nguoi_dung = ? AND id_goi_combo = ?";
                $updateStmt = $conn->prepare($updateSql);
                $updateStmt->bind_param("isii", $rating, $comment, $id_nguoi_dung, $combo_id);
                $updateStmt->execute();
                $updateStmt->close();
            } else {
                // Create new review for combo
                $insertSql = "INSERT INTO danh_gia (id_nguoi_dung, id_tour, id_goi_combo, so_sao, binh_luan, ngay_tao) VALUES (?, NULL, ?, ?, ?, NOW())";
                $insertStmt = $conn->prepare($insertSql);
                
                if (!$insertStmt) {
                    throw new Exception("Lỗi prepare statement: " . $conn->error);
                }
                
                $insertStmt->bind_param("iiss", $id_nguoi_dung, $combo_id, $rating, $comment);
                
                if (!$insertStmt->execute()) {
                    throw new Exception("Lỗi thực thi query: " . $insertStmt->error);
                }
                
                $insertStmt->close();
            }
            
            $checkReviewStmt->close();
        } else {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Tour hoặc Combo không hợp lệ']);
            exit;
        }
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Đánh giá đã được lưu thành công'
        ]);
        exit;
    } catch (Exception $e) {
        error_log('❌ handleCreateReview Error: ' . $e->getMessage());
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $e->getMessage()
        ]);
        exit;
    }
}

// =====================================================
// GET KHUYẾN MÃI - Lấy dữ liệu khuyến mãi từ database
// =====================================================

function handleGetKhuyenMai() {
    global $conn;
    
    try {
        // Query lấy dữ liệu khuyến mãi từ bảng khuyen_mai
        $query = "
            SELECT 
                km.id,
                km.code,
                km.loai_giam,
                km.gia_tri_giam,
                km.so_lan_toi_da,
                km.so_lan_da_su_dung,
                km.co_hieu_luc_tu,
                km.co_hieu_luc_den,
                km.trang_thai,
                km.id_tour,
                km.id_goi_combo,
                t.id as tour_id,
                t.ten as tour_name,
                t.gia as tour_price,
                t.url_anh_chinh as tour_image,
                t.id_dia_diem as tour_dest_id,
                gc.id as combo_id,
                gc.ten as combo_name,
                gc.gia_ban as combo_price,
                gc.gia_goc as combo_original_price,
                gc.url_anh as combo_image
            FROM khuyen_mai km
            LEFT JOIN tour t ON km.id_tour = t.id
            LEFT JOIN goi_combo gc ON km.id_goi_combo = gc.id
            LIMIT 20
        ";
        
        $result = $conn->query($query);
        
        if (!$result) {
            throw new Exception("Database query error: " . $conn->error);
        }
        
        $khuyenMaiData = [];
        while ($row = $result->fetch_assoc()) {
            // Sanitize image paths
            if (!empty($row['tour_image'])) {
                $row['tour_image'] = sanitizeImagePath($row['tour_image']);
            }
            if (!empty($row['combo_image'])) {
                $row['combo_image'] = sanitizeImagePath($row['combo_image']);
            }
            $khuyenMaiData[] = $row;
        }
        
        // Trả dữ liệu thành JSON
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'data' => $khuyenMaiData,
            'total' => count($khuyenMaiData)
        ]);
        exit;
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $e->getMessage()
        ]);
        exit;
    }
}

/**
 * Lấy danh sách điểm đến từ database
 */
function handleGetFilterDestinations() {
    global $conn;
    
    try {
        $query = "
            SELECT DISTINCT d.id, d.ten as destination_name
            FROM dia_diem d
            INNER JOIN tour t ON d.id = t.id_dia_diem
            WHERE t.trang_thai = 1
            ORDER BY d.ten ASC
        ";
        
        $result = $conn->query($query);
        
        if (!$result) {
            throw new Exception("Database query error: " . $conn->error);
        }
        
        $destinations = [];
        while ($row = $result->fetch_assoc()) {
            $destinations[] = $row;
        }
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'data' => $destinations
        ]);
        exit;
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Lỗi: ' . $e->getMessage()
        ]);
        exit;
    }
}

?>
