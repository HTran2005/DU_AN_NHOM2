<?php

return [
    'host' => $_ENV['REDIS_HOST'] ?? '',
    'port' => (int)($_ENV['REDIS_PORT'] ?? 10000),
    'password' => $_ENV['REDIS_PASSWORD'] ?? '',
];