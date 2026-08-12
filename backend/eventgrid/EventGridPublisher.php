<?php

/**
 * ==========================================================
 * TripTo - Azure Event Grid Publisher
 * ==========================================================
 *
 * Chức năng
 * ----------
 * - Publish sự kiện đăng nhập (LoginResult) lên Azure Event Grid
 *   dạng Event Grid schema (eventType/data).
 *
 * Sự kiện "LoginResult" được tạo trong mỗi lần đăng nhập:
 *   - status = "Success" : username/email + password đúng.
 *   - status = "False"   : username/email hoặc password sai (KHÔNG phải
 *                          lỗi của Function - Function chỉ chạy/ghi log).
 * LƯU Ý: Invocation "Success" của Azure Function chỉ nghĩa là Function
 * chạy xong; kết quả đăng nhập thực sự nằm ở trường data.status.
 *
 * Bảo mật
 * -------
 * - KHÔNG bao giờ gửi password / password hash / access token
 *   / refresh token trong event hoặc log.
 * - Chỉ gửi status, username, email, timestamp, message
 *   (message KHÔNG chứa mật khẩu).
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
     * Publish sự kiện đăng nhập (LoginResult) lên Event Grid.
     *
     * @param string      $status    'Success' hoặc 'False'
     * @param string      $email     email người dùng (login identifier)
     * @param int|null    $userId    id người dùng (tuỳ chọn)
     * @param string|null $reason    lý do thất bại (tuỳ chọn, KHÔNG chứa mật khẩu)
     * @param string|null $username  tên đăng nhập (mặc định = email)
     * @param string|null $message   nội dung hiển thị (mặc định theo status)
     * @return bool true nếu Event Grid trả HTTP 2xx
     */
    public static function publishLoginEvent($status, $email = '', $userId = null, $reason = null, $username = null, $message = null)
    {
        $endpoint = defined('EVENTGRID_LOGIN_TOPIC_ENDPOINT') ? EVENTGRID_LOGIN_TOPIC_ENDPOINT : '';
        $key      = defined('EVENTGRID_LOGIN_TOPIC_KEY') ? EVENTGRID_LOGIN_TOPIC_KEY : '';

        if (empty($endpoint) || empty($key)) {
            error_log('[EventGrid] Thiếu cấu hình EVENTGRID_LOGIN_TOPIC_ENDPOINT/KEY');
            return false;
        }

        $now = gmdate('Y-m-d\TH:i:s\Z');

        if ($message === null) {
            $message = $status === 'Success' ? 'Đăng nhập thành công' : 'Đăng nhập thất bại';
        }

        $data = [
            'status'    => $status,
            'username'  => !empty($username) ? $username : $email,
            'email'     => $email,
            'timestamp' => $now,
            'message'   => $message
        ];
        if (!empty($userId)) {
            $data['userId'] = $userId;
        }
        if (!empty($reason)) {
            $data['reason'] = $reason;
        }
        $data['loginMethod'] = 'username_or_email';

        $event = [
            [
                'id'          => bin2hex(random_bytes(16)),
                'eventType'   => 'LoginResult',
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