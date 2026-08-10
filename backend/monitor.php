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
      'timeout' => 1
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
 * Chuyển duration (ms) sang định dạng TimeSpan dd.hh:mm:ss.fffffff
 * (App Insights yêu cầu đúng định dạng này, nếu không sẽ trả 400)
 */
function monitorMsToTimeSpan($ms) {
  $ms = (float)$ms;
  $days = floor($ms / 86400000);
  $ms -= $days * 86400000;
  $hours = floor($ms / 3600000);
  $ms -= $hours * 3600000;
  $minutes = floor($ms / 60000);
  $ms -= $minutes * 60000;
  $seconds = floor($ms / 1000);
  $ms -= $seconds * 1000;
  $fraction = round($ms * 10000); // 7 chữ số: 1ms = 10^4 đơn vị 100ns
  return sprintf('%d.%02d:%02d:%02d.%07d', $days, $hours, $minutes, $seconds, $fraction);
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
      'duration' => monitorMsToTimeSpan($durationMs),
      'success' => $success,
      'responseCode' => (string)$httpCode,
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
 * Track dependency (MySQL/Redis/HTTP ra ngoài) -> bảng dependencies
 * Gọi khi backend thực hiện gọi database hoặc service bên ngoài.
 */
function monitorTrackDependency($target, $name, $data, $durationMs, $success = true, $type = 'SQL', $resultCode = '') {
  $data = [
    'baseType' => 'RemoteDependencyData',
    'baseData' => [
      'ver' => 2,
      'id' => uniqid(),
      'name' => $name,
      'type' => $type,
      'target' => $target,
      'data' => $data,
      'duration' => monitorMsToTimeSpan($durationMs),
      'success' => $success,
      'resultCode' => (string)$resultCode
    ]
  ];
  monitorSend(monitorEnvelope('Microsoft.ApplicationInsights.RemoteDependency', $data));
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

    // Bỏ qua telemetry cho các GET nhanh (<250ms) - đây là phần lớn các request load dữ liệu.
    // Giảm lượng HTTP call nền, giúp PHP-FPM worker không bị chiếm giữ -> web ổn định hơn.
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    if ($method === 'GET' && $durationMs < 250) {
      return;
    }

    monitorTrackRequest($name, $url, $durationMs, $httpCode, $success);
  }
}
