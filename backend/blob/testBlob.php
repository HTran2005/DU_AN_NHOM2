<?php
require_once "../config.php";

echo "<h2>Azure Blob Storage Test</h2>";

echo "Storage Account: " . AZURE_STORAGE_ACCOUNT . "<br>";
echo "Container: " . AZURE_STORAGE_CONTAINER . "<br>";

if (defined('AZURE_STORAGE_CONNECTION_STRING')) {
    echo "<span style='color:green'>Connection String OK</span>";
} else {
    echo "<span style='color:red'>Connection String Missing</span>";
}