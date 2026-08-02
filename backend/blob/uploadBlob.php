<?php

require_once __DIR__ . '/BlobStorage.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'success' => false,
        'message' => 'Only POST method is allowed.'
    ]);
    exit;
}

if (!isset($_FILES['image'])) {
    echo json_encode([
        'success' => false,
        'message' => 'No image uploaded.'
    ]);
    exit;
}

$file = $_FILES['image'];

$blobName = time() . "_" . basename($file['name']);

$storage = new BlobStorage();

$result = $storage->upload(
    $file['tmp_name'],
    $blobName
);

echo json_encode($result);