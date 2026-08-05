<?php

/**
 * ==========================================================
 * TripTo - Send Message to Azure Service Bus
 * ==========================================================
 *
 * Nhận dữ liệu booking từ Website
 * Gửi lên Azure Service Bus Queue
 *
 * URL:
 * http://localhost/backend/servicebus/sendMessage.php
 *
 * ==========================================================
 */

header('Content-Type: application/json; charset=UTF-8');

require_once __DIR__ . '/ServiceBus.php';

try {

    /**
     * ------------------------------------------------------
     * Chỉ chấp nhận POST
     * ------------------------------------------------------
     */
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {

        http_response_code(405);

        echo json_encode([
            'success' => false,
            'message' => 'Method Not Allowed'
        ]);

        exit;
    }

    /**
     * ------------------------------------------------------
     * Đọc JSON từ Request Body
     * ------------------------------------------------------
     */
    $rawInput = file_get_contents("php://input");

    $input = json_decode($rawInput, true);

    if (!$input) {

        throw new Exception("Không nhận được dữ liệu JSON.");

    }

    /**
     * ------------------------------------------------------
     * Kiểm tra dữ liệu bắt buộc
     * ------------------------------------------------------
     */
    $requiredFields = [

        'booking_id',
        'tour_id',
        'user_id',
        'customer_name',
        'email',
        'phone',
        'price'

    ];

    foreach ($requiredFields as $field) {

        if (!isset($input[$field])) {

            throw new Exception("Thiếu trường: {$field}");

        }

    }

    /**
     * ------------------------------------------------------
     * Tạo Message
     * ------------------------------------------------------
     */
    $message = [

        "booking_id"    => $input["booking_id"],

        "tour_id"       => $input["tour_id"],

        "user_id"       => $input["user_id"],

        "customer_name" => $input["customer_name"],

        "email"         => $input["email"],

        "phone"         => $input["phone"],

        "price"         => $input["price"],

        "created_at"    => date("Y-m-d H:i:s")

    ];

    /**
     * ------------------------------------------------------
     * Gửi lên Azure Service Bus
     * ------------------------------------------------------
     */
    $serviceBus = new ServiceBus();

    $result = $serviceBus->send($message);

    /**
     * ------------------------------------------------------
     * Trả kết quả
     * ------------------------------------------------------
     */
    echo json_encode([

        "success" => $result["success"],

        "status" => $result["status"],

        "message" => $result["message"],

        "data" => $message

    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

}
catch (Exception $e) {

    http_response_code(500);

    echo json_encode([

        "success" => false,

        "message" => $e->getMessage()

    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

}