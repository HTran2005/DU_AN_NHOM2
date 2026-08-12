<?php
/**
 * RedisClient wrapper: supports Predis or phpredis (Redis)
 * Provides safe helpers for setex, exists, mget, del and reports availability.
 */
require_once __DIR__ . '/redis.php';

class RedisClient {
    private $client = null;
    private $available = false;
    private $using = null; // 'predis' or 'phpredis'

    public function __construct() {
        $cfg = require __DIR__ . '/redis.php';
        $host = $cfg['host'] ?? null;
        $port = $cfg['port'] ?? 10000;
        $password = $cfg['password'] ?? null;

        if (empty($host)) {
            $this->available = false;
            return;
        }

        // Try Predis first (if installed via composer)
        if (class_exists('\Predis\Client')) {
            try {
                $params = [
                    'scheme' => 'tls',
                    'host' => $host,
                    'port' => (int)$port,
                ];
                if (!empty($password)) $params['password'] = $password;
                $options = ['timeout' => 2.0];
                $this->client = new \Predis\Client($params, $options);
                // test ping
                $this->client->ping();
                $this->available = true;
                $this->using = 'predis';
                return;
            } catch (Throwable $e) {
                error_log('Redis (Predis) connect error: ' . $e->getMessage());
                $this->client = null;
            }
        }

        // Try phpredis extension
        if (class_exists('Redis')) {
            try {
                $r = new \Redis();
                // Use tls:// prefix to enable TLS
                $hostUri = (strpos($host, 'tls://') === 0 || strpos($host, 'rediss://') === 0) ? $host : 'tls://' . $host;
                // timeout 2 seconds
                $connected = $r->connect($hostUri, (int)$port, 2.0);
                if ($connected) {
                    if (!empty($password)) {
                        // Auth if password provided
                        $r->auth($password);
                    }
                    // optional: set read timeout
                    $this->client = $r;
                    $this->available = true;
                    $this->using = 'phpredis';
                    return;
                }
            } catch (Throwable $e) {
                error_log('Redis (phpredis) connect error: ' . $e->getMessage());
                $this->client = null;
            }
        }

        $this->available = false;
    }

    public function available() {
        return $this->available === true;
    }

    private function safeCall(callable $fn) {
        if (!$this->available || $this->client === null) return null;
        try {
            return $fn($this->client, $this->using);
        } catch (Throwable $e) {
            error_log('Redis operation error: ' . $e->getMessage());
            return null;
        }
    }

    public function setex($key, $ttl, $value = 1) {
        return $this->safeCall(function($c, $using) use ($key, $ttl, $value) {
            if ($using === 'predis') {
                return $c->setex($key, (int)$ttl, $value);
            }
            // phpredis
            return $c->setex($key, (int)$ttl, $value);
        });
    }

    public function exists($key) {
        return $this->safeCall(function($c, $using) use ($key) {
            if ($using === 'predis') {
                // Predis v1: exists returns int(1) or int(0)
                return $c->exists($key) ? true : false;
            }
            return $c->exists($key) ? true : false;
        });
    }

    public function get($key) {
        return $this->safeCall(function($c, $using) use ($key) {
            if ($using === 'predis') {
                return $c->get($key);
            }
            return $c->get($key);
        });
    }

    public function del($key) {
        return $this->safeCall(function($c, $using) use ($key) {
            if ($using === 'predis') {
                return $c->del([$key]);
            }
            return $c->del($key);
        });
    }

    public function mget(array $keys) {
        return $this->safeCall(function($c, $using) use ($keys) {
            if (empty($keys)) return [];
            if ($using === 'predis') {
                return $c->mget($keys);
            }
            return $c->mGet($keys);
        });
    }

    // =============================================
    // Redis SET operations (dùng cho Favorite/Wishlist)
    // Mỗi function trả null khi Redis lỗi (caller tự fallback).
    // =============================================

    /**
     * SADD key member -> trả số lượng member được thêm (0 nếu đã tồn tại).
     */
    public function sadd($key, $member) {
        return $this->safeCall(function($c, $using) use ($key, $member) {
            if ($using === 'predis') {
                return (int)$c->sadd($key, [$member]);
            }
            return (int)$c->sAdd($key, $member);
        });
    }

    /**
     * SREM key member -> trả số lượng member bị xoá (0 nếu không tồn tại).
     */
    public function srem($key, $member) {
        return $this->safeCall(function($c, $using) use ($key, $member) {
            if ($using === 'predis') {
                return (int)$c->srem($key, [$member]);
            }
            return (int)$c->sRem($key, $member);
        });
    }

    /**
     * SCARD key -> số lượng phần tử trong Set.
     */
    public function scard($key) {
        return $this->safeCall(function($c, $using) use ($key) {
            if ($using === 'predis') {
                return (int)$c->scard($key);
            }
            return (int)$c->sCard($key);
        });
    }

    /**
     * SISMEMBER key member -> true/false.
     */
    public function sismember($key, $member) {
        return $this->safeCall(function($c, $using) use ($key, $member) {
            if ($using === 'predis') {
                return $c->sismember($key, $member) ? true : false;
            }
            return $c->sIsMember($key, $member) ? true : false;
        });
    }

    /**
     * SMEMBERS key -> mảng member (rỗng nếu Set không có phần tử).
     */
    public function smembers($key) {
        return $this->safeCall(function($c, $using) use ($key) {
            if ($using === 'predis') {
                return $c->smembers($key);
            }
            return $c->sMembers($key);
        });
    }

    /**
     * EXPIRE key seconds -> đặt lại TTL cho key.
     */
    public function expire($key, $ttl) {
        return $this->safeCall(function($c, $using) use ($key, $ttl) {
            if ($using === 'predis') {
                return $c->expire($key, (int)$ttl);
            }
            return $c->expire($key, (int)$ttl);
        });
    }
}

// helper factory
function getRedisClientInstance() {
    static $inst = null;
    if ($inst === null) {
        $inst = new RedisClient();
    }
    return $inst;
}
