<?php
/**
 * Database Connection Configuration
 * Kết nối đến cơ sở dữ liệu MySQL
 */

// Database Configuration / Cấu hình Database
define('DB_HOST', 'localhost');      // Máy chủ
define('DB_USER', 'root');           // Username
define('DB_PASS', '');               // Password (mặc định rỗng cho XAMPP)
define('DB_NAME', 'tripto');         // Tên cơ sở dữ liệu

// Charset
define('DB_CHARSET', 'utf8mb4');

// Error Reporting
error_reporting(E_ALL);
ini_set('display_errors', 0);        // Không hiển thị lỗi cho user
ini_set('log_errors', 1);            // Ghi log lỗi

// Kết nối đến Database
try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
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
?>
