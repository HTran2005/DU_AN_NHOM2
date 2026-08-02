<?php

require_once __DIR__ . '/../config.php';

class BlobStorage
{
    /**
     * Upload file lên Azure Blob Storage
     * Chức năng này sẽ được hoàn thiện sau khi cài Azure SDK.
     */
    public function upload($localFile, $blobName)
    {
        return [
            'success' => false,
            'message' => 'Azure Blob SDK chưa được cài đặt.',
            'blobName' => $blobName
        ];
    }

    /**
     * Xóa blob
     */
    public function delete($blobName)
    {
        return false;
    }

    /**
     * Lấy URL blob
     */
    public function getUrl($blobName)
    {
        return sprintf(
            "https://%s.blob.core.windows.net/%s/%s",
            AZURE_STORAGE_ACCOUNT,
            AZURE_STORAGE_CONTAINER,
            $blobName
        );
    }
}