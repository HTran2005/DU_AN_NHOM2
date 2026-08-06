<?php
/**
 * Azure Maps Subscription Key
 * Đọc từ biến môi trường MAPS_KEY (App Service App Setting / Key Vault).
 * KHÔNG lưu key trực tiếp trong mã nguồn.
 * Xuất ra JS: window.MAPS_KEY = "..."
 */
header('Content-Type: application/javascript; charset=utf-8');

$key = getenv('MAPS_KEY') ?: '';
// Xử lý đặc biệt khi key chưa được cấu hình (tránh lỗi map)
if (empty($key)) {
    echo "window.MAPS_KEY = '';";
    exit;
}

echo "window.MAPS_KEY = " . json_encode($key) . ";";