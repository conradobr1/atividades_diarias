<?php
declare(strict_types=1);

if (parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) !== '/api/atividades') {
    return false;
}

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

function responder(int $status, array $dados): never
{
    http_response_code($status);
    echo json_encode($dados, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
    exit;
}

try {
    $metodo = $_SERVER['REQUEST_METHOD'];
    if ($metodo === 'GET') {
        $mes = $_GET['mes'] ?? '';
        if (!is_string($mes) || !preg_match('/\A[0-9]{4}-(0[1-9]|1[0-2])\z/', $mes)) {
            responder(400, ['erro' => 'Informe um mês válido.']);
        }
    } elseif ($metodo === 'POST') {
        $dados = json_decode(file_get_contents('php://input'), true);
        $dia = $dados['dia'] ?? null;
        $atividade = $dados['atividade'] ?? null;
        if (!is_string($dia) || !preg_match('/\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/', $dia, $partes)
            || !checkdate((int)$partes[2], (int)$partes[3], (int)$partes[1])) {
            responder(400, ['erro' => 'Informe uma data válida.']);
        }
        if (!is_string($atividade) || trim($atividade) === '' || mb_strlen(trim($atividade)) > 500) {
            responder(400, ['erro' => 'Digite uma atividade de até 500 caracteres.']);
        }
    } else {
        header('Allow: GET, POST');
        responder(405, ['erro' => 'Método não permitido.']);
    }

    $arquivo = getenv('ATIVIDADES_DB') ?: __DIR__ . '/atividades.sqlite';
    $banco = new PDO('sqlite:' . $arquivo);
    $banco->exec('PRAGMA busy_timeout = 5000');
    $banco->exec('CREATE TABLE IF NOT EXISTS atividades (
        id INTEGER PRIMARY KEY, dia TEXT NOT NULL, atividade TEXT NOT NULL
    )');
    $banco->exec('CREATE INDEX IF NOT EXISTS atividades_dia ON atividades (dia)');

    if ($metodo === 'GET') {
        $consulta = $banco->prepare('SELECT id, dia, atividade FROM atividades
            WHERE dia BETWEEN :inicio AND :fim ORDER BY dia DESC, id DESC');
        $consulta->execute(['inicio' => $mes . '-01', 'fim' => $mes . '-31']);
        responder(200, $consulta->fetchAll(PDO::FETCH_ASSOC));
    }

    $insercao = $banco->prepare('INSERT INTO atividades (dia, atividade) VALUES (:dia, :atividade)');
    $insercao->execute(['dia' => $dia, 'atividade' => trim($atividade)]);
    responder(201, ['id' => (int)$banco->lastInsertId()]);
} catch (Throwable $erro) {
    error_log($erro->getMessage());
    responder(500, ['erro' => 'O servidor não conseguiu acessar o banco de dados.']);
}
