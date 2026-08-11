<?php
/**
 * Redis configuration (Azure Cache for Redis)
 * Đọc từ biến môi trường; ưu tiên $_ENV, fallback getenv().
 * CHÚ Ý: file này KHÔNG được có ký tự thừa trước <?php,
 * nếu không output sẽ bắt đầu sớm -> phá vỡ session_start() trên toàn app.
 */
return [
    'host' => (($_ENV['REDIS_HOST'] ?? '') !== '') ? $_ENV['REDIS_HOST'] : (getenv('REDIS_HOST') ?: ''),
    'port' => (int)((($_ENV['REDIS_PORT'] ?? '') !== '') ? $_ENV['REDIS_PORT'] : (getenv('REDIS_PORT') ?: 10000)),
    'password' => (($_ENV['REDIS_PASSWORD'] ?? '') !== '') ? $_ENV['REDIS_PASSWORD'] : (getenv('REDIS_PASSWORD') ?: ''),
];
