<?php
/**
 * Database Connection Configuration + Azure Monitoring
 * Kết nối đến cơ sở dữ liệu MySQL + Application Insights
 */

// Database Configuration / Cấu hình Database
define('DB_HOST', getenv('DB_HOST') ?: 'tripto-mysql-db.mysql.database.azure.com');
define('DB_USER', getenv('DB_USER') ?: 'nhom2');
define('DB_PASS', getenv('DB_PASS') ?: 'tripto@123');
define('DB_NAME', getenv('DB_NAME') ?: 'tripto_db');

// Charset
define('DB_CHARSET', 'utf8mb4');

// Microsoft Entra ID (đăng nhập bằng Microsoft)
// Client ID và Tenant ID lấy từ App Registration trong Entra ID
// Có thể đặt qua biến môi trường (App Service) để tránh lộ trong mã nguồn
define('MS_CLIENT_ID', getenv('MS_CLIENT_ID') ?: 'd3803479-bbab-498a-ab4c-d4c9e36a3a66');
define('MS_TENANT_ID', getenv('MS_TENANT_ID') ?: 'common');
define('MS_AUTHORITY', getenv('MS_AUTHORITY') ?: ('https://login.microsoftonline.com/' . MS_TENANT_ID . '/v2.0'));

// Error Reporting
error_reporting(E_ALL);
ini_set('display_errors', 0);        // Không hiển thị lỗi cho user
ini_set('log_errors', 1);            // Ghi log lỗi

// Azure Application Insights
// Instrumentation Key được lấy từ output của Bicep deployment
// Cập nhật giá trị này sau khi chạy scripts/deploy-monitoring.ps1
define('APPINSIGHTS_INSTRUMENTATIONKEY', getenv('APPINSIGHTS_INSTRUMENTATIONKEY') ?: '2c156544-aac3-495d-ad96-9377a65ddcd2');

/**
 * --------------------------------------------------------
 * Azure Service Bus Configuration
 * --------------------------------------------------------
 */
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

// Kết nối đến Database
try {
    $conn = mysqli_init();
    mysqli_ssl_set($conn, NULL, NULL, NULL, NULL, NULL);
    $conn->real_connect(DB_HOST, DB_USER, DB_PASS, DB_NAME, 3306, NULL, MYSQLI_CLIENT_SSL);
    
    // Xử lý lỗi kết nối
    if ($conn->connect_error) {
        throw new Exception("Database Connection Error: " . $conn->connect_error);
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

// Hàm helper để đóng connect
function closeConnection() {
    global $conn;
    if ($conn) {
        $conn->close();
    }
}

// Auto-send telemetry khi script kết thúc
register_shutdown_function(function () {
    $httpCode = http_response_code();
    $success = ($httpCode >= 200 && $httpCode < 500);
    monitorEndRequest($httpCode, $success);

    // Track PHP fatal errors
    $lastError = error_get_last();
    if ($lastError && in_array($lastError['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        monitorTrackException(new ErrorException(
            $lastError['message'], 0, $lastError['type'],
            $lastError['file'], $lastError['line']
        ));
    }
});
?>
