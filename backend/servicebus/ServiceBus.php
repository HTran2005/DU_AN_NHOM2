<?php

/**
 * ==========================================================
 * TripTo - Azure Service Bus Helper
 * ==========================================================
 *
 * Chức năng
 * ----------
 * - Tạo SAS Token
 * - Gửi Message
 * - Nhận Message
 * - Xóa Message
 *
 * Sử dụng REST API Azure Service Bus
 *
 * PHP 8+
 * GuzzleHTTP
 *
 * ==========================================================
 */

// Service Bus không cần kết nối Database -> bỏ qua DB để endpoint không phụ thuộc MySQL
if (!defined('APP_SKIP_DB_CONNECT')) {
    define('APP_SKIP_DB_CONNECT', true);
}

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../vendor/autoload.php';

use GuzzleHttp\Client;
use GuzzleHttp\Exception\RequestException;

class ServiceBus
{

    /**
     * HTTP Client
     */
    private Client $client;

    /**
     * Queue URL
     */
    private string $queueUrl;

    /**
     * Constructor
     */
    public function __construct()
    {

        $this->client = new Client([
            'timeout' => 30
        ]);

        $host = parse_url(SERVICEBUS_ENDPOINT, PHP_URL_HOST);

        $this->queueUrl =
            "https://{$host}/" .
            SERVICEBUS_QUEUE;
    }

    /**
     * -------------------------------------------------------
     * Tạo SAS Token
     * -------------------------------------------------------
     */
    private function generateSasToken($expiry = 3600)
    {

        $uri = strtolower($this->queueUrl);

        $expires = time() + $expiry;

        $stringToSign =
            rawurlencode($uri) .
            "\n" .
            $expires;

        $signature = base64_encode(

            hash_hmac(
                'sha256',
                $stringToSign,
                base64_decode(SERVICEBUS_KEY),
                true
            )

        );

        return sprintf(

            "SharedAccessSignature sr=%s&sig=%s&se=%d&skn=%s",

            rawurlencode($uri),

            rawurlencode($signature),

            $expires,

            SERVICEBUS_POLICY

        );

    }

    /**
     * -------------------------------------------------------
     * Header chung
     * -------------------------------------------------------
     */
    private function buildHeaders(array $extra = [])
    {

        return array_merge([

            'Authorization' => $this->generateSasToken(),

            'Content-Type' => 'application/json'

        ], $extra);

    }

    /**
     * =======================================================
     * Gửi Message lên Azure Service Bus
     * =======================================================
     *
     * @param array $data
     * @return array
     */
    public function send(array $data): array
    {

        try {

            $response = $this->client->post(

                $this->queueUrl . "/messages",

                [

                    'headers' => $this->buildHeaders([

                        'BrokerProperties' => json_encode([
                            'Label' => 'TripTo Booking'
                        ])

                    ]),

                    'body' => json_encode(
                        $data,
                        JSON_UNESCAPED_UNICODE
                    )

                ]

            );

            return [

                'success' => true,

                'status' => $response->getStatusCode(),

                'message' => 'Message sent successfully.'

            ];

        }

        catch (RequestException $e) {

    $status = $e->getCode();

    if ($status == 0) {
        $status = 500;
    }

    return [
        "success" => false,
        "status" => $status,
        "message" => $e->getMessage()
    ];
}

    }

    /**
     * =======================================================
     * Nhận 1 Message từ Queue (Peek-Lock)
     * =======================================================
     *
     * @return array
     */
    public function receive(): array
    {

        try {

            $response = $this->client->post(

                $this->queueUrl . "/messages/head",

                [

                    'headers' => $this->buildHeaders([

                        'Content-Length' => 0

                    ])

                ]

            );

            $headers = $response->getHeaders();

            $body = (string)$response->getBody();

            return [

                'success' => true,

                'status' => $response->getStatusCode(),

                'data' => json_decode($body, true),

                // Azure sẽ trả Location để dùng xóa message
                'location' => $headers['Location'][0] ?? null

            ];

        }

       catch (RequestException $e) {

    $status = $e->getCode();

    if ($status == 0) {
        $status = 500;
    }

    return [
        "success" => false,
        "status" => $status,
        "message" => $e->getMessage()
    ];
}
    }

    /**
     * =======================================================
     * Xóa Message sau khi xử lý thành công
     * =======================================================
     *
     * Azure Service Bus trả về URL Location khi receive().
     * Chỉ cần gửi DELETE tới URL này là message sẽ bị xóa khỏi Queue.
     *
     * @param string $location
     * @return array
     */
    public function deleteMessage(string $location): array
    {

        try {

            $response = $this->client->delete(

                $location,

                [

                    'headers' => [

                        'Authorization' => $this->generateSasToken()

                    ]

                ]

            );

            return [

                'success' => true,

                'status' => $response->getStatusCode(),

                'message' => 'Message deleted successfully.'

            ];

        }

        catch (RequestException $e) {

    $status = $e->getCode();

    if ($status == 0) {
        $status = 500;
    }

    return [
        "success" => false,
        "status" => $status,
        "message" => $e->getMessage()
    ];
}

    }

}