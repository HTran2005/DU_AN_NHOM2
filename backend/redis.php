<?php

return [
    'host' => getenv('REDIS_HOST'),
    'port' => getenv('REDIS_PORT') ?: 10000,
    'password' => getenv('REDIS_PASSWORD'),
];