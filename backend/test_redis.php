<?php

require_once __DIR__ . '/vendor/autoload.php';

use Dotenv\Dotenv;

$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

require_once __DIR__ . '/RedisClient.php';

echo "REDIS_HOST: ";
echo getenv('REDIS_HOST') ?: 'NOT FOUND';
echo PHP_EOL;

echo "REDIS_PORT: ";
echo getenv('REDIS_PORT') ?: 'NOT FOUND';
echo PHP_EOL;

$redis = getRedisClientInstance();

if (!$redis->available()) {
    echo "Redis connection: FAILED" . PHP_EOL;
    exit(1);
}

echo "Redis connection: OK" . PHP_EOL;

$result = $redis->setex(
    'tripto:test',
    60,
    'hello'
);

echo $result
    ? "Redis SET: OK" . PHP_EOL
    : "Redis SET: FAILED" . PHP_EOL;