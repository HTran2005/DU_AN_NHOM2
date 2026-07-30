<?php
/**
 * TripTo - Azure Application Insights Monitoring
 * =================================================
 * Gửi telemetry trực tiếp qua REST API (không cần Composer).
 *
 * Cách dùng:
 *   1. File này được include từ config.php
 *   2. monitorTrackRequest(), monitorTrackException(), monitorTrackEvent() tự động gọi
 *   3. Xem data tại: Portal -> Log Analytics -> Logs
 */

/**
 * Gửi dữ liệu lên Application Insights endpoint
 */
function monitorSend($data) {
  $ikey = defined('APPINSIGHTS_INSTRUMENTATIONKEY') ? APPINSIGHTS_INSTRUMENTATIONKEY : '';
  if (empty($ikey) || $ikey === 'YOUR_INSTRUMENTATION_KEY_HERE') return;

  $payload = json_encode($data);
  $url = 'https://dc.services.visualstudio.com/v2/track';

  $options = [
    'http' => [
      'method' => 'POST',
      'header' => "Content-Type: application/x-json-stream\r\n",
      'content' => $payload,
      'timeout' => 2
    ]
  ];
  $context = stream_context_create($options);
  @file_get_contents($url, false, $context);
}

/**
 * Envelope chuẩn cho App Insights
 */
function monitorEnvelope($name, $data) {
  $ikey = defined('APPINSIGHTS_INSTRUMENTATIONKEY') ? APPINSIGHTS_INSTRUMENTATIONKEY : '';
  return [[
    'name' => $name,
    'time' => gmdate('Y-m-d\TH:i:s\Z'),
    'iKey' => $ikey,
    'tags' => [
      'ai.cloud.role' => 'tripto-backend',
      'ai.cloud.roleInstance' => gethostname(),
      'ai.internal.sdkVersion' => 'php:direct'
    ],
    'data' => [
      'baseType' => $data['baseType'],
      'baseData' => $data['baseData']
    ]
  ]];
}

/**
 * Track request (gọi tự động từ config.php)
 */
function monitorTrackRequest($name, $url, $durationMs, $httpCode, $success = true) {
  $data = [
    'baseType' => 'RequestData',
    'baseData' => [
      'ver' => 2,
      'id' => uniqid(),
      'name' => $name,
      'duration' => $durationMs . '.0',
      'success' => $success,
      'responseCode' => $httpCode,
      'url' => $url,
      'properties' => [
        'method' => $_SERVER['REQUEST_METHOD'] ?? 'GET'
      ]
    ]
  ];
  monitorSend(monitorEnvelope('Microsoft.ApplicationInsights.Request', $data));
}

/**
 * Track exception (gọi tự động khi có lỗi PHP)
 */
function monitorTrackException($message, $file = '', $line = 0) {
  $data = [
    'baseType' => 'ExceptionData',
    'baseData' => [
      'ver' => 2,
      'handledAt' => 'PHP',
      'exceptions' => [[
        'typeName' => 'Error',
        'message' => $message,
        'hasFullStack' => false,
        'stack' => "$message at $file:$line"
      ]]
    ]
  ];
  monitorSend(monitorEnvelope('Microsoft.ApplicationInsights.Exception', $data));
}

/**
 * Track event (login, register, booking, v.v.)
 */
function monitorTrackEvent($name, $properties = [], $measurements = []) {
  $data = [
    'baseType' => 'EventData',
    'baseData' => [
      'ver' => 2,
      'name' => $name,
      'properties' => $properties,
      'measurements' => $measurements
    ]
  ];
  monitorSend(monitorEnvelope('Microsoft.ApplicationInsights.Event', $data));
}

/**
 * Gọi đầu request (auto từ config.php)
 */
function monitorBeginRequest() {
  $GLOBALS['_monitor_start'] = microtime(true);
}

/**
 * Gọi cuối request (auto từ config.php)
 */
function monitorEndRequest($httpCode = 200, $success = true) {
  if (isset($GLOBALS['_monitor_start'])) {
    $durationMs = (microtime(true) - $GLOBALS['_monitor_start']) * 1000;
    $url = $_SERVER['REQUEST_URI'] ?? 'unknown';
    $name = ($_SERVER['REQUEST_METHOD'] ?? 'GET') . ' ' . parse_url($url, PHP_URL_PATH);
    monitorTrackRequest($name, $url, $durationMs, $httpCode, $success);
  }
}
