<?php

require_once __DIR__ . '/vendor/autoload.php';

use Dotenv\Dotenv;
use Predis\Client;

$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

$host = $_ENV['REDIS_HOST'];
$port = (int) $_ENV['REDIS_PORT'];
$password = $_ENV['REDIS_PASSWORD'];

echo "Host: " . $host . PHP_EOL;
echo "Port: " . $port . PHP_EOL;
echo "Password: " . (!empty($password) ? "LOADED" : "NOT FOUND") . PHP_EOL;

try {

    $redis = new Client([
        'scheme' => 'tls',
        'host' => $host,
        'port' => $port,
        'password' => $password,
        'timeout' => 10,
    ]);

    echo "Connecting..." . PHP_EOL;

    $response = $redis->ping();

    echo "PING: ";
    echo $response . PHP_EOL;

    $redis->setex('tripto:test', 60, 'hello');

    echo "SET: OK" . PHP_EOL;

    $value = $redis->get('tripto:test');

    echo "GET: " . $value . PHP_EOL;

} catch (\Throwable $e) {

    echo PHP_EOL;
    echo "REDIS ERROR:" . PHP_EOL;
    echo get_class($e) . PHP_EOL;
    echo $e->getMessage() . PHP_EOL;
}