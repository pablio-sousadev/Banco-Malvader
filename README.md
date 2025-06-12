# Banco-Malvader

Documentação do Sistema – Banco Malvader

1. Introdução

O Banco Malvader é um sistema bancário desenvolvido para fins acadêmicos, com o objetivo de simular as principais operações de um banco real. O sistema foi desenvolvido na disciplina de Laboratório de Banco de Dados da Universidade Católica de Brasília.


---

2. Tecnologias Utilizadas

Componente	Tecnologia Utilizada

Back-End	Java
Front-End	HTML, CSS e JavaScript
Banco de Dados	MySQL
Integração	Não concluída (sistema entregue com partes independentes)



---

3. Funcionalidades Implementadas

3.1. Back-End (Java)

Cadastro de contas (Corrente, Poupança e Investimento)

Cadastro de clientes e funcionários

Operações bancárias simuladas:

Abertura de conta

Alteração de dados

Consultas


Validações de dados (ex.: CPF único, limite de funcionários)

Procedures e triggers implementados no MySQL

Arquitetura MVC parcial implementada

Camada DAO para comunicação com o banco


3.2. Front-End (HTML/CSS/JS)

Telas implementadas:

Tela de login (visual, sem integração)

Tela de menu (Cliente e Funcionário)

Tela de cadastro de conta (formulário)

Tela de operações básicas (formulários)

Tela de extrato e relatórios (estrutura HTML pronta)


Estilização com CSS e responsividade básica


3.3. Banco de Dados (MySQL)

Modelo relacional implementado

Tabelas principais:

Usuário

Funcionário

Cliente

Conta (Corrente, Poupança e Investimento)

Transações

Auditoria


Procedures implementadas:

Geração de score de crédito


Triggers implementadas:

Atualização automática de saldo após transações

Limitação de depósitos diários


Views criadas:

Resumo de contas por cliente

Movimentações recentes




---

4. Funcionalidades Não Implementadas

Integração entre Front-End e Back-End

Sistema de autenticação com OTP (optado por não utilizar)

Exportação de relatórios para PDF/Excel



---

5. Requisitos Atendidos

Requisito	Status

CRUD de contas e usuários	✅ Concluído
Operações básicas bancárias	✅ Concluído
Auditoria e segurança	✅ Concluído
Exportação de relatórios	❌ Não feito
Integração completa	❌ Não feito
OTP (autenticação)	❌ Não feito



---

6. Considerações Finais

Apesar de não ter sido possível realizar a integração completa do sistema, as partes individuais (front-end, back-end e banco de dados) foram desenvolvidas de forma organizada e com foco no aprendizado das tecnologias propostas.

O projeto demonstrou domínio em:

Modelagem e manipulação de banco de dados MySQL

Programação orientada a objetos com Java

Desenvolvimento de interfaces web com HTML, CSS e JavaScript



---

7. Integrantes do Grupo

Páblio de Sousa Lourenço– Responsável pelo Front-End, Organização e Documentação

Thiago Beijamin da Silva Gomes – Responsável pelo Back-End em Java

Vinícius Resende Caldeira– Responsável pelo Banco de Dados MySQL

Vinícius Leal Duarte – Responsável por Integração e Testes

