<?php

/**
 * ==========================================================
 * TripTo - Receive Message from Azure Service Bus
 * ==========================================================
 *
 * Chức năng:
 *  - Nhận 1 message từ Queue
 *  - Hiển thị nội dung message
 *  - Xóa message khỏi Queue sau khi xử lý
 *
 * URL:
 * http://localhost/DU_AN_NHOM2/backend/servicebus/receiveMessage.php
 *
 * ==========================================================
 */

header('Content-Type: application/json; charset=UTF-8');

require_once __DIR__ . '/ServiceBus.php';

try {

    /**
     * ------------------------------------------------------
     * Khởi tạo Service Bus
     * ------------------------------------------------------
     */
    $serviceBus = new ServiceBus();

    /**
     * ------------------------------------------------------
     * Nhận Message
     * ------------------------------------------------------
     */
    $result = $serviceBus->receive();

    if (!$result["success"]) {

        throw new Exception($result["message"]);

    }

    /**
     * ------------------------------------------------------
     * Lấy dữ liệu
     * ------------------------------------------------------
     */
    $message = $result["data"];

    /**
     * ------------------------------------------------------
     * Xóa Message nếu có Location
     * ------------------------------------------------------
     */
    $deleteResult = null;

    if (!empty($result["location"])) {

        $deleteResult = $serviceBus->deleteMessage(
            $result["location"]
        );

    }

    /**
     * ------------------------------------------------------
     * Trả kết quả
     * ------------------------------------------------------
     */
    echo json_encode([

        "success" => true,

        "message" => "Receive message successfully.",

        "queue_message" => $message,

        "delete_result" => $deleteResult

    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

}
catch (Exception $e) {

    http_response_code(500);

    echo json_encode([

        "success" => false,

        "message" => $e->getMessage()

    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

}