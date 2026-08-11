<?php
/**
 * Database Connection Configuration + Azure Monitoring
 * Kết nối đến cơ sở dữ liệu MySQL + Application Insights
 */

// Database Configuration / Cấu hình Database
define('DB_HOST', getenv('DB_HOST') ?: 'tripto-mysql-db.mysql.database.azure.com');
define('DB_USER', getenv('DB_USER') ?: 'nhom2');
define('DB_PASS', getenv('DB_PASS') ?: '');
define('DB_NAME', getenv('DB_NAME') ?: 'tripto_db');

// Azure Blob Storage Configuration
define('AZURE_STORAGE_ACCOUNT', getenv('AZURE_STORAGE_ACCOUNT') ?: getenv('AZURE_STORAGE_ACCOUNT_NAME') ?: '');
define('AZURE_STORAGE_CONTAINER', getenv('AZURE_STORAGE_CONTAINER') ?: getenv('AZURE_STORAGE_CONTAINER_NAME') ?: 'tour-images');
define('AZURE_STORAGE_CONNECTION_STRING', getenv('AZURE_STORAGE_CONNECTION_STRING') ?: '');
define('AZURE_STORAGE_ACCOUNT_KEY', getenv('AZURE_STORAGE_ACCOUNT_KEY') ?: '');

define('JWT_SECRET', getenv('JWT_SECRET') ?: '');

// Charset
define('DB_CHARSET', 'utf8mb4');

// Microsoft Entra ID (đăng nhập bằng Microsoft)
// Client ID và Tenant ID lấy từ App Registration trong Entra ID
// Có thể đặt qua biến môi trường (App Service) để tránh lộ trong mã nguồn
define('MS_CLIENT_ID', getenv('MS_CLIENT_ID') ?: '');
define('MS_TENANT_ID', getenv('MS_TENANT_ID') ?: 'common');
define('MS_AUTHORITY', getenv('MS_AUTHORITY') ?: ('https://login.microsoftonline.com/' . MS_TENANT_ID . '/v2.0'));

// Error Reporting
error_reporting(E_ALL);
ini_set('display_errors', 0);        // Không hiển thị lỗi cho user
ini_set('log_errors', 1);            // Ghi log lỗi

// ===== CORS - cho phép frontend gọi API qua API Management (cross-origin) =====
// Phải gửi header Access-Control-Allow-Origin, nếu không trình duyệt sẽ chặn
// request và admin page hiển thị "Lỗi lấy dữ liệu" (Failed to fetch).
$corsOrigin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '*';
header('Access-Control-Allow-Origin: ' . $corsOrigin);
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, Origin, X-Requested-With, Accept');
// Allow credentials (cookies) so frontend can send session cookie with fetch
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Max-Age: 86400');
header('Vary: Origin');

// Xử lý preflight request (OPTIONS) - trình duyệt gửi trước khi gọi API
if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Azure Application Insights
// Instrumentation Key được lấy từ output của Bicep deployment
// Cập nhật giá trị này sau khi chạy scripts/deploy-monitoring.ps1
define('APPINSIGHTS_INSTRUMENTATIONKEY', getenv('APPINSIGHTS_INSTRUMENTATIONKEY') ?: '');


// Service Bus Namespace Endpoint
define(
    'SERVICEBUS_ENDPOINT',
    getenv('SERVICEBUS_ENDPOINT')
        ?: 'sb://sb-tripto-backend.servicebus.windows.net/'
);

// Queue Name
define(
    'SERVICEBUS_QUEUE',
    getenv('SERVICEBUS_QUEUE')
        ?: 'booking-queue'
);

// Shared Access Policy
define(
    'SERVICEBUS_POLICY',
    getenv('SERVICEBUS_POLICY')
        ?: 'RootManageSharedAccessKey'
);

// Shared Access Key (bí mật - đọc từ biến môi trường / Key Vault, KHÔNG hardcode)
define(
    'SERVICEBUS_KEY',
    getenv('SERVICEBUS_KEY')
        ?: ''
);

    
// Load monitoring helper
require_once __DIR__ . '/monitor.php';

// Auto-track request
monitorBeginRequest();

// Kết nối đến Database (bỏ qua nếu script không cần DB - ví dụ Service Bus)
if (!defined('APP_SKIP_DB_CONNECT')) {
try {
    // Dùng kết nối persistent (p:) để PHP-FPM tái sử dụng connection giữa các request
    // -> tránh phải bắt tay TCP+TLS lại mỗi request (giảm độ trễ rõ rệt trên Azure MySQL)
    // Lưu ý: Azure MySQL có thể đóng connection không hoạt động (wait_timeout / firewall / restart),
    // nên PHP-FPM có thể tái sử dụng một socket đã chết -> lỗi "MySQL server has gone away"
    // khiến thao tác lưu (INSERT/UPDATE) thỉnh thoảng thất bại. Do đó luôn kiểm tra ping
    // và tự kết nối lại nếu pooled connection bị cũ/chết.

    $conn = mysqli_init();
    mysqli_ssl_set($conn, NULL, NULL, NULL, NULL, NULL);
    $conn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 10);
    $conn->real_connect('p:' . DB_HOST, DB_USER, DB_PASS, DB_NAME, 3306, NULL, MYSQLI_CLIENT_SSL);

    // Xử lý lỗi kết nối
    if ($conn->connect_error) {
        throw new Exception("Database Connection Error: " . $conn->connect_error);
    }

    // Kiểm tra connection persistent có còn "sống" hay không.
    // Nếu server đã đóng (idle timeout), ping() trả false -> đóng (recycle khỏi pool)
    // và mở connection mới ngay để request hiện tại không bị lỗi giữa chừng.
    if (!$conn->ping()) {
        @$conn->close();

        $conn = mysqli_init();
        mysqli_ssl_set($conn, NULL, NULL, NULL, NULL, NULL);
        $conn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 10);
        $conn->real_connect('p:' . DB_HOST, DB_USER, DB_PASS, DB_NAME, 3306, NULL, MYSQLI_CLIENT_SSL);
        if ($conn->connect_error) {
            throw new Exception("Database Connection Error: " . $conn->connect_error);
        }
    }

    // Thiết lập charset
    if (!$conn->set_charset(DB_CHARSET)) {
        throw new Exception("Error setting charset: " . $conn->error);
    }

    // Kết nối thành công (không cần thông báo cho user)
} catch (Exception $e) {
    // Ghi log lỗi
    error_log("Database Error: " . $e->getMessage());
    
    // Trả lỗi cho user (dạng JSON)
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Lỗi kết nối cơ sở dữ liệu. Vui lòng thử lại sau.'
    ]);
    exit;
}
}

// Hàm helper để đóng connect
if (!function_exists('closeConnection')) {
    function closeConnection() {
        global $conn;
        if ($conn) {
            $conn->close();
        }
    }
}

// Helper gửi 1 dependency (MySQL query) lên App Insights -> bảng dependencies
// Cách dùng: gói câu lệnh query để đong thời gian rồi gọi hàm này.
function monitorTrackDbQuery($sql, $durationMs = 0, $success = true, $target = DB_HOST) {
  monitorTrackDependency($target, 'MySQL Query', $sql, $durationMs, $success, 'SQL', $success ? '200' : '500');
}

// Auto-send telemetry khi script kết thúc
register_shutdown_function(function () {
    $lastError = error_get_last();
    $fatal = $lastError && in_array($lastError['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR]);

    // Gửi response về client ngay lập tức, telemetry chạy nền không chặn request
    // (chỉ áp dụng khi không có fatal error để handler lỗi vẫn ghi JSON được)
    if (!$fatal && function_exists('fastcgi_finish_request')) {
        @fastcgi_finish_request();
    }

    $httpCode = http_response_code();
    // Request gặp exception (đăng nhập sai, lỗi nghiệp vụ...) phải được ghi là FAILED
    // dù HTTP vẫn 200/400 (< 500), nếu không App Insights sẽ nhận Success=true sai.
    $failed = !empty($GLOBALS['_monitor_request_failed']);
    $success = !$failed && ($httpCode >= 200 && $httpCode < 500);
    monitorEndRequest($httpCode, $success);

    // Track PHP fatal errors
    if ($fatal) {
        monitorTrackException(new ErrorException(
            $lastError['message'], 0, $lastError['type'],
            $lastError['file'], $lastError['line']
        ));
    }
});
?>
