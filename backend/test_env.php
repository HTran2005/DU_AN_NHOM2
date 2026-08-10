<?php

require_once __DIR__ . '/vendor/autoload.php';

use Dotenv\Dotenv;

$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

echo "HOST = ";
var_dump($_ENV['REDIS_HOST'] ?? null);

echo "PORT = ";
var_dump($_ENV['REDIS_PORT'] ?? null);