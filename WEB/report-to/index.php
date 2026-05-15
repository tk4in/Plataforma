<?php

// 1. Configurações de segurança e cabeçalho
header('Content-Type: application/json');

// 2. Verificar se a requisição é POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); // Method Not Allowed
    echo json_encode(['error' => 'Apenas POST permitido']);
    exit;
}

// 3. Receber o corpo da requisição (raw JSON)
$jsonRaw = file_get_contents('php://input');

// 4. Validar se o JSON foi recebido
if (empty($jsonRaw)) {
    http_response_code(400); // Bad Request
    echo json_encode(['error' => 'Nenhum dado recebido']);
    exit;
}

// 5. Decodificar o JSON
// O 'true' transforma em array associativo
$reports = json_decode($jsonRaw, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode(['error' => 'JSON inválido']);
    exit;
}

// 6. Processar/Salvar o relatório
// É altamente recomendável salvar em log para análise posterior
// e não processar em tempo real para evitar lentidão ou falhas.
$logFile = 'csp-violations.log';

// Formatar dados para o log
$logEntry = "[" . date('Y-m-d H:i:s') . "] " . $jsonRaw . PHP_EOL;

// Salva no arquivo (modo append)
file_put_contents($logFile, $logEntry, FILE_APPEND);

// 7. Responder ao navegador que o relatório foi recebido
http_response_code(202); // Accepted
echo json_encode(['status' => 'ok']);
?>
