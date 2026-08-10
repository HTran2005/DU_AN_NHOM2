<?php

require_once __DIR__ . '/../config.php';

class BlobStorage
{
    /**
     * Upload file lên Azure Blob Storage
     * Chức năng này sẽ được hoàn thiện sau khi cài Azure SDK.
     */
    private string $accountName;
    private string $accountKey;
    private string $container;
    private string $endpoint;

    public function __construct()
    {
        $this->accountName = AZURE_STORAGE_ACCOUNT;
        $this->accountKey = AZURE_STORAGE_ACCOUNT_KEY;
        $this->container = AZURE_STORAGE_CONTAINER;

        if (!empty(AZURE_STORAGE_CONNECTION_STRING)) {
            $this->parseConnectionString(AZURE_STORAGE_CONNECTION_STRING);
        }

        if (empty($this->accountName) || empty($this->accountKey)) {
            throw new Exception('Azure Storage configuration missing. Please set AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_ACCOUNT_KEY or AZURE_STORAGE_CONNECTION_STRING.');
        }

        if (empty($this->endpoint)) {
            $this->endpoint = sprintf('https://%s.blob.core.windows.net', $this->accountName);
        }
    }

    private function parseConnectionString(string $connectionString): void
    {
        $parts = explode(';', trim($connectionString));
        foreach ($parts as $part) {
            if (strpos($part, '=') === false) {
                continue;
            }
            [$key, $value] = explode('=', $part, 2);
            $key = trim($key);
            $value = trim($value);
            if ($key === 'AccountName') {
                $this->accountName = $value;
            }
            if ($key === 'AccountKey') {
                $this->accountKey = $value;
            }
            if ($key === 'BlobEndpoint' && empty($this->endpoint)) {
                $this->endpoint = $value;
            }
        }
    }

    public function upload(string $localFilePath, string $blobName, string $contentType): array
    {
        if (!file_exists($localFilePath)) {
            return [
                'success' => false,
                'message' => 'File không tồn tại: ' . $localFilePath,
                'blobName' => $blobName
            ];
        }

        $content = file_get_contents($localFilePath);
        if ($content === false) {
            return [
                'success' => false,
                'message' => 'Không thể đọc file tạm.',
                'blobName' => $blobName
            ];
        }

        $url = sprintf('%s/%s/%s', $this->endpoint, $this->container, rawurlencode($blobName));
        $contentLength = strlen($content);
        $date = gmdate('D, d M Y H:i:s') . ' GMT';
        $headers = [
            'x-ms-blob-type: BlockBlob',
            'x-ms-date: ' . $date,
            'x-ms-version: 2020-10-02',
            'Content-Type: ' . $contentType,
            'Content-Length: ' . $contentLength
        ];

        $authorization = $this->buildAuthorizationHeader('PUT', $headers, $blobName, $contentLength, $contentType);
        $headers[] = 'Authorization: ' . $authorization;

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $content);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HEADER, true);
        curl_setopt($ch, CURLOPT_FAILONERROR, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

        $response = curl_exec($ch);
        $statusCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($statusCode === 201) {
            return [
                'success' => true,
                'message' => 'Upload ảnh lên Azure Blob Storage thành công.',
                'url' => $url,
                'blobName' => $blobName
            ];
        }

        return [
            'success' => false,
            'message' => 'Azure Blob upload failed. Status: ' . $statusCode . '. Error: ' . $error,
            'response' => $response,
            'blobName' => $blobName
        ];
    }

    public function uploadFromData(string $content, string $blobName, string $contentType): array
    {
        $tempFile = tempnam(sys_get_temp_dir(), 'azure_blob_');
        if ($tempFile === false) {
            return [
                'success' => false,
                'message' => 'Không thể tạo tập tin tạm để upload.'
            ];
        }

        file_put_contents($tempFile, $content);
        $result = $this->upload($tempFile, $blobName, $contentType);
        unlink($tempFile);
        return $result;
    }

    public function delete(string $blobName): bool
    {
        try {
            $url = sprintf('%s/%s/%s', $this->endpoint, $this->container, rawurlencode($blobName));
            $date = gmdate('D, d M Y H:i:s') . ' GMT';
            $headers = [
                'x-ms-date: ' . $date,
                'x-ms-version: 2020-10-02'
            ];
            $authorization = $this->buildAuthorizationHeader('DELETE', $headers, $blobName, 0, '');
            $headers[] = 'Authorization: ' . $authorization;

            $ch = curl_init($url);
            curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
            curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_HEADER, true);
            curl_setopt($ch, CURLOPT_FAILONERROR, false);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

            curl_exec($ch);
            $statusCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            return in_array($statusCode, [202, 404], true);
        } catch (Exception $e) {
            return false;
        }
    }

    public function getUrl(string $blobName): string
    {
        return sprintf('https://%s.blob.core.windows.net/%s/%s', $this->accountName, $this->container, $blobName);
    }

    private function buildAuthorizationHeader(string $method, array $headers, string $blobName, int $contentLength, string $contentType): string
    {
        $contentEncoding = '';
        $contentLanguage = '';
        $contentMD5 = '';
        $dateHeader = '';
        $ifModifiedSince = '';
        $ifMatch = '';
        $ifNoneMatch = '';
        $ifUnmodifiedSince = '';
        $range = '';

        $canonicalizedHeaders = $this->buildCanonicalizedHeaders($headers);
        $canonicalizedResource = $this->buildCanonicalizedResource($blobName);

        $stringToSign = implode("\n", [
            strtoupper($method),
            $contentEncoding,
            $contentLanguage,
            $contentLength > 0 ? $contentLength : '',
            $contentMD5,
            $contentType,
            $dateHeader,
            $ifModifiedSince,
            $ifMatch,
            $ifNoneMatch,
            $ifUnmodifiedSince,
            $range,
            $canonicalizedHeaders . $canonicalizedResource
        ]);

        $signature = base64_encode(hash_hmac('sha256', $stringToSign, base64_decode($this->accountKey), true));
        return sprintf('SharedKey %s:%s', $this->accountName, $signature);
    }

    private function buildCanonicalizedHeaders(array $headers): string
    {
        $canonicalHeaders = [];
        foreach ($headers as $header) {
            if (stripos($header, 'x-ms-') === 0) {
                [$name, $value] = explode(':', $header, 2);
                $canonicalHeaders[strtolower(trim($name))] = trim($value);
            }
        }
        ksort($canonicalHeaders);
        $lines = [];
        foreach ($canonicalHeaders as $name => $value) {
            $lines[] = $name . ':' . $value;
        }
        return implode("\n", $lines) . "\n";
    }

    private function buildCanonicalizedResource(string $blobName): string
    {
        // URL phải khớp canonicalized resource dùng trong SharedKey signature.
        // Trước đây request dùng rawurlencode($blobName) nhưng signature dùng tên thật
        // -> lệch nhau khi tên có ký tự đặc biệt -> 403 SignatureDoesNotMatch.
        return sprintf('/%s/%s/%s', $this->accountName, $this->container, rawurlencode($blobName));
    }
}