<?php

/**
 * ==========================================================
 * TripTo - Azure Event Grid Publisher
 * ==========================================================
 *
 * Chức năng
 * ----------
 * - Publish sự kiện đăng nhập (User.Login) lên Azure Event Grid
 *   dạng Event Grid schema (eventType/data).
 *
 * Bảo mật
 * -------
 * - KHÔNG bao giờ gửi password / password hash / access token
 *   / refresh token trong event hoặc log.
 * - Chỉ gửi status, loginMethod, userId, email (nếu cần),
 *   timestamp, reason (khi thất bại).
 *
 * Sử dụng cURL extension (có sẵn trên PHP) — không phụ thuộc Composer.
 *
 * Cấu hình (qua biến môi trường / App Settings):
 *   EVENTGRID_LOGIN_TOPIC_ENDPOINT  = https://<topic>.<region>-1.eventgrid.azure.net/api/events?api-version=2018-01-01
 *   EVENTGRID_LOGIN_TOPIC_KEY       = access key của topic
 * ==========================================================
 */

class EventGridPublisher
{
    /**
     * Publish sự kiện đăng nhập lên Event Grid.
     *
     * @param string $status      'Success' hoặc 'False'
     * @param string $email       email người dùng (tuỳ chọn)
     * @param int|null $userId    id người dùng (tuỳ chọn)
     * @param string|null $reason  lý do thất bại (tuỳ chọn, KHÔNG chứa mật khẩu)
     * @return bool true nếu Event Grid trả HTTP 2xx
     */
    public static function publishLoginEvent($status, $email = '', $userId = null, $reason = null)
    {
        $endpoint = defined('EVENTGRID_LOGIN_TOPIC_ENDPOINT') ? EVENTGRID_LOGIN_TOPIC_ENDPOINT : '';
        $key      = defined('EVENTGRID_LOGIN_TOPIC_KEY') ? EVENTGRID_LOGIN_TOPIC_KEY : '';

        if (empty($endpoint) || empty($key)) {
            error_log('[EventGrid] Thiếu cấu hình EVENTGRID_LOGIN_TOPIC_ENDPOINT/KEY');
            return false;
        }

        $now = gmdate('Y-m-d\TH:i:s\Z');

        $data = [
            'status'      => $status,
            'loginMethod' => 'username_or_email'
        ];
        if (!empty($userId)) {
            $data['userId'] = $userId;
        }
        if (!empty($email)) {
            $data['email'] = $email;
        }
        if (!empty($reason)) {
            $data['reason'] = $reason;
        }
        $data['timestamp'] = $now;

        $event = [
            [
                'id'          => bin2hex(random_bytes(16)),
                'eventType'   => 'User.Login',
                'subject'     => 'user/login',
                'eventTime'   => $now,
                'dataVersion' => '1.0',
                'data'        => $data
            ]
        ];

        $body = json_encode($event, JSON_UNESCAPED_UNICODE);

        $ch = curl_init($endpoint);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $body,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                'aeg-sas-key: ' . $key
            ],
            CURLOPT_TIMEOUT        => 10,
            CURLOPT_CONNECTTIMEOUT => 10
        ]);

        $response = curl_exec($ch);
        $httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlErr  = curl_error($ch);
        curl_close($ch);

        if ($httpCode >= 200 && $httpCode < 300) {
            return true;
        }

        error_log(
            '[EventGrid] Publish thất bại (HTTP ' . $httpCode . '): ' . $curlErr .
            ' | response: ' . substr((string) $response, 0, 200)
        );
        return false;
    }
}
