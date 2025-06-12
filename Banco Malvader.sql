CREATE DATABASE banco_malvader;
USE banco_malvader;

-- Tabela usuario
CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    data_nascimento DATE NOT NULL,
    telefone VARCHAR(15) NOT NULL,
    tipo_usuario ENUM('FUNCIONARIO', 'CLIENTE') NOT NULL,
    senha_hash VARCHAR(32) NOT NULL,
    otp_ativo VARCHAR(6),
    otp_expiracao DATETIME
);

-- Tabela endereco
CREATE TABLE endereco (
    id_endereco INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    cep VARCHAR(10) NOT NULL,
    local VARCHAR(100) NOT NULL,
    numero_casa INT NOT NULL,
    bairro VARCHAR(50) NOT NULL,
    cidade VARCHAR(50) NOT NULL,
    estado CHAR(2) NOT NULL,
    complemento VARCHAR(50),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    INDEX idx_cep (cep)
);

-- Tabela agencia
CREATE TABLE agencia (
    id_agencia INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    codigo_agencia VARCHAR(10) UNIQUE NOT NULL,
    endereco_id INT NOT NULL,
    FOREIGN KEY (endereco_id) REFERENCES endereco(id_endereco)
);

-- Tabela funcionario
CREATE TABLE funcionario (
    id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    codigo_funcionario VARCHAR(20) UNIQUE NOT NULL,
    cargo ENUM('ESTAGIARIO', 'ATENDENTE', 'GERENTE') NOT NULL,
    id_supervisor INT,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    FOREIGN KEY (id_supervisor) REFERENCES funcionario(id_funcionario)
);

-- Tabela cliente
CREATE TABLE cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    score_credito DECIMAL(5,2) DEFAULT 0,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

-- Tabela conta
CREATE TABLE conta (
    id_conta INT AUTO_INCREMENT PRIMARY KEY,
    numero_conta VARCHAR(20) UNIQUE NOT NULL,
    id_agencia INT NOT NULL,
    saldo DECIMAL(15,2) NOT NULL DEFAULT 0,
    tipo_conta ENUM('POUPANCA', 'CORRENTE', 'INVESTIMENTO') NOT NULL,
    id_cliente INT NOT NULL,
    data_abertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('ATIVA', 'ENCERRADA', 'BLOQUEADA') NOT NULL DEFAULT 'ATIVA',
    FOREIGN KEY (id_agencia) REFERENCES agencia(id_agencia),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    INDEX idx_numero_conta (numero_conta)
);

-- Tabela conta_poupanca
CREATE TABLE conta_poupanca (
    id_conta_poupanca INT AUTO_INCREMENT PRIMARY KEY,
    id_conta INT NOT NULL UNIQUE,
    taxa_rendimento DECIMAL(5,2) NOT NULL,
    ultimo_rendimento DATETIME,
    FOREIGN KEY (id_conta) REFERENCES conta(id_conta)
);

-- Tabela conta_corrente
CREATE TABLE conta_corrente (
    id_conta_corrente INT AUTO_INCREMENT PRIMARY KEY,
    id_conta INT NOT NULL UNIQUE,
    limite DECIMAL(15,2) NOT NULL DEFAULT 0,
    data_vencimento DATE NOT NULL,
    taxa_manutencao DECIMAL(5,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (id_conta) REFERENCES conta(id_conta)
);

-- Tabela conta_investimento
CREATE TABLE conta_investimento (
    id_conta_investimento INT AUTO_INCREMENT PRIMARY KEY,
    id_conta INT NOT NULL UNIQUE,
    perfil_risco ENUM('BAIXO', 'MEDIO', 'ALTO') NOT NULL,
    valor_minimo DECIMAL(15,2) NOT NULL,
    taxa_rendimento_base DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (id_conta) REFERENCES conta(id_conta)
);

-- Tabela transacao
CREATE TABLE transacao (
    id_transacao INT AUTO_INCREMENT PRIMARY KEY,
    id_conta_origem INT NOT NULL,
    id_conta_destino INT,
    tipo_transacao ENUM('DEPOSITO', 'SAQUE', 'TRANSFERENCIA', 'TAXA', 'RENDIMENTO') NOT NULL,
    valor DECIMAL(15,2) NOT NULL,
    data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descricao VARCHAR(100),
    FOREIGN KEY (id_conta_origem) REFERENCES conta(id_conta),
    FOREIGN KEY (id_conta_destino) REFERENCES conta(id_conta),
    INDEX idx_data_hora (data_hora)
);

-- Tabela auditoria
CREATE TABLE auditoria (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    acao VARCHAR(50) NOT NULL,
    data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    detalhes TEXT,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

-- Tabela relatorio
CREATE TABLE relatorio (
    id_relatorio INT AUTO_INCREMENT PRIMARY KEY,
    id_funcionario INT NOT NULL,
    tipo_relatorio VARCHAR(50) NOT NULL,
    data_geracao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    conteudo TEXT NOT NULL,
    FOREIGN KEY (id_funcionario) REFERENCES funcionario(id_funcionario)
);

DELIMITER $$

-- Trigger para atualizar saldo após transações
CREATE TRIGGER atualizar_saldo AFTER INSERT ON transacao
FOR EACH ROW
BEGIN
    IF NEW.tipo_transacao = 'DEPOSITO' THEN
        UPDATE conta SET saldo = saldo + NEW.valor WHERE id_conta = NEW.id_conta_origem;
    ELSEIF NEW.tipo_transacao IN ('SAQUE', 'TAXA') THEN
        UPDATE conta SET saldo = saldo - NEW.valor WHERE id_conta = NEW.id_conta_origem;
    ELSEIF NEW.tipo_transacao = 'TRANSFERENCIA' THEN
        UPDATE conta SET saldo = saldo - NEW.valor WHERE id_conta = NEW.id_conta_origem;
        UPDATE conta SET saldo = saldo + NEW.valor WHERE id_conta = NEW.id_conta_destino;
    END IF;
END $$

-- Trigger para validação de senha forte
CREATE TRIGGER validar_senha BEFORE UPDATE ON usuario
FOR EACH ROW
BEGIN
    IF NEW.senha_hash REGEXP '^[0-9a-f]{32}$' THEN -- Assume MD5
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Senha deve ser atualizada via procedure com validação';
    END IF;
END $$

-- Trigger para limite de depósito diário
CREATE TRIGGER limite_deposito BEFORE INSERT ON transacao
FOR EACH ROW
BEGIN
    DECLARE total_dia DECIMAL(15,2);
    
    IF NEW.tipo_transacao = 'DEPOSITO' THEN
        SELECT SUM(valor) INTO total_dia
        FROM transacao
        WHERE id_conta_origem = NEW.id_conta_origem
        AND tipo_transacao = 'DEPOSITO'
        AND DATE(data_hora) = DATE(NEW.data_hora);
        
        IF (IFNULL(total_dia, 0) + NEW.valor) > 10000 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Limite diário de depósito excedido';
        END IF;
    END IF;
END $$

DELIMITER ;

DELIMITER $$

-- Procedimento para gerar OTP
CREATE PROCEDURE gerar_otp(IN id_usuario INT)
BEGIN
    DECLARE novo_otp VARCHAR(6);
    SET novo_otp = LPAD(FLOOR(RAND() * 1000000), 6, '0');
    
    UPDATE usuario SET otp_ativo = novo_otp, otp_expiracao = NOW() + INTERVAL 5 MINUTE
    WHERE id_usuario = id_usuario;
    
    SELECT novo_otp;
END $$

-- Procedimento para calcular score de crédito
CREATE PROCEDURE calcular_score_credito(IN id_cliente INT)
BEGIN
    DECLARE total_trans DECIMAL(15,2);
    DECLARE media_trans DECIMAL(15,2);
    
    SELECT SUM(valor), AVG(valor) INTO total_trans, media_trans
    FROM transacao t
    JOIN conta c ON t.id_conta_origem = c.id_conta
    WHERE c.id_cliente = id_cliente AND t.tipo_transacao IN ('DEPOSITO', 'SAQUE');
    
    UPDATE cliente SET score_credito = LEAST(100, (total_trans / 1000) + (media_trans / 100))
    WHERE id_cliente = id_cliente;
END $$

DELIMITER ;

-- Resumo de Contas por Cliente
CREATE VIEW vw_resumo_contas AS
SELECT c.id_cliente, u.nome, COUNT(co.id_conta) AS total_contas, SUM(co.saldo) AS saldo_total
FROM cliente c
JOIN usuario u ON c.id_usuario = u.id_usuario
JOIN conta co ON c.id_cliente = co.id_cliente
GROUP BY c.id_cliente, u.nome;

-- Movimentações Recentes
CREATE VIEW vw_movimentacoes_recentes AS
SELECT t.*, c.numero_conta, u.nome AS cliente
FROM transacao t
JOIN conta c ON t.id_conta_origem = c.id_conta
JOIN cliente cl ON c.id_cliente = cl.id_cliente
JOIN usuario u ON cl.id_usuario = u.id_usuario
WHERE t.data_hora >= NOW() - INTERVAL 90 DAY;


-- Inserir um usuário administrador
INSERT INTO usuario (nome, cpf, data_nascimento, telefone, tipo_usuario, senha_hash)
VALUES ('Admin', '12345678901', '1980-01-01', '61999999999', 'FUNCIONARIO', MD5('admin123'));

-- Obter o ID do usuário inserido
SET @admin_id = LAST_INSERT_ID();

-- Inserir endereço
INSERT INTO endereco (id_usuario, cep, local, numero_casa, bairro, cidade, estado)
VALUES (@admin_id, '70000000', 'SQS 100', 1, 'Asa Sul', 'Brasília', 'DF');

-- Inserir agência
INSERT INTO agencia (nome, codigo_agencia, endereco_id)
VALUES ('Agência Central', '001', LAST_INSERT_ID());

-- Inserir funcionário admin
INSERT INTO funcionario (id_usuario, codigo_funcionario, cargo)
VALUES (@admin_id, 'ADMIN001', 'GERENTE');

SELECT * FROM usuario;



-- 1. Inserir o usuário (base para cliente)
INSERT INTO usuario (nome, cpf, data_nascimento, telefone, tipo_usuario, senha_hash)
VALUES (
    'João Silva', 
    '12345678901', 
    '1985-05-15', 
    '61999998888', 
    'CLIENTE', 
    MD5('senhaSegura123')
);

-- Guardar o ID do usuário inserido
SET @id_usuario = LAST_INSERT_ID();

-- 2. Inserir endereço
INSERT INTO endereco (id_usuario, cep, local, numero_casa, bairro, cidade, estado, complemento)
VALUES (
    @id_usuario,
    '70000000',
    'SQN 302 Bloco A',
    12,
    'Asa Norte',
    'Brasília',
    'DF',
    'Apartmento 301'
);

-- 3. Inserir o cliente
INSERT INTO cliente (id_usuario, score_credito)
VALUES (
    @id_usuario,
    75.50  -- Score inicial
);

-- Guardar o ID do cliente
SET @id_cliente = LAST_INSERT_ID();

-- 4. Criar uma conta corrente para o cliente
INSERT INTO conta (numero_conta, id_agencia, tipo_conta, id_cliente, saldo)
VALUES (
    '123456789',  -- Número da conta (com dígito verificador se aplicável)
    1,            -- ID da agência (deve existir na tabela agencia)
    'CORRENTE',
    @id_cliente,
    1000.00       -- Saldo inicial
);

-- Guardar o ID da conta
SET @id_conta = LAST_INSERT_ID();

-- 5. Detalhes da conta corrente
INSERT INTO conta_corrente (id_conta, limite, data_vencimento, taxa_manutencao)
VALUES (
    @id_conta,
    2000.00,     -- Limite do cheque especial
    '2025-12-31', -- Data de vencimento do pacote
    20.00        -- Taxa mensal
);

-- 6. (Opcional) Criar uma transação de exemplo
INSERT INTO transacao (id_conta_origem, tipo_transacao, valor, descricao)
VALUES (
    @id_conta,
    'DEPOSITO',
    500.00,
    'Depósito inicial'
);

-- Verificar o cliente criado
SELECT * FROM usuario WHERE id_usuario = @id_usuario;
SELECT * FROM cliente WHERE id_cliente = @id_cliente;

-- Verificar a conta e saldo
SELECT * FROM conta WHERE id_cliente = @id_cliente;
SELECT * FROM conta_corrente WHERE id_conta = @id_conta;

-- Verificar transações
SELECT * FROM transacao WHERE id_conta_origem = @id_conta;