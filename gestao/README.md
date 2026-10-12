# Controle Financeiro

App web de **contas a pagar e a receber** para várias empresas, com clientes/fornecedores, serviços, **controle de estoque** e **dashboards**. Tudo fica salvo online no Supabase: dá para acessar e alterar de qualquer computador ou celular, e as telas abertas se atualizam sozinhas quando alguém muda algo.

Arquivo do app: `gestao/index.html` (uma única página, sem build).
O controle de caixa antigo (`index.html` na raiz) continua funcionando como antes.

## O que tem

| Aba | Recursos |
|---|---|
| **Dashboard** | Resultado, recebido, pago, a receber/a pagar em aberto (com vencidos), valor em estoque; gráficos de fluxo de caixa mensal, resultado mensal, previsão das próximas 12 semanas, receita por serviço, maiores clientes, despesas por categoria e comparativo entre empresas; contas vencendo em 7 dias; alertas de estoque. Filtro por período. |
| **Contas a pagar / receber** | Cadastro com cliente/fornecedor, serviço, categoria, vencimento, parcelas (repetição mensal), baixa (pagamento/recebimento) e estorno. Filtros por tipo, situação (pendente, vencido, pago, cancelado), cliente, serviço, categoria, datas (vencimento ou pagamento) e busca. Totais do filtro e exportação em CSV (abre no Excel). |
| **Clientes e fornecedores** | Cadastro com totais recebidos e em aberto por cliente; botão "Ver contas" já filtra as contas daquele cliente. |
| **Serviços** | Preço padrão (preenche o valor da conta ao escolher o serviço) e faturamento por serviço. |
| **Estoque** | Produtos com saldo, mínimo, custo, preço de venda e situação. Entradas, saídas e ajustes de inventário com histórico filtrável. Opção de gerar automaticamente a conta a pagar (compra) ou a receber (venda). |
| **Empresas e backup** | Cadastro de quantas empresas quiser; backup em JSON (baixar e importar). |

O seletor **Empresa** no topo troca entre uma empresa ou **Todas as empresas** (visão consolidada). Clientes e serviços podem ser exclusivos de uma empresa ou compartilhados entre todas.

## Configuração (uma vez só)

O app usa o mesmo projeto Supabase do controle de caixa (as chaves estão no topo do `<script>` em `gestao/index.html`).

1. **Criar as tabelas** — no painel do Supabase: *SQL Editor → New query*, cole todo o conteúdo de [`schema.sql`](schema.sql) e clique em *Run*.
2. **Criar os usuários** — em *Authentication → Users → Add user*, crie um usuário (e-mail e senha) para cada pessoa que vai usar o app. Também é possível criar pelo botão "Primeiro acesso? Criar conta" na tela de login.
3. **Fechar novos cadastros (importante)** — depois de criar os usuários, vá em *Authentication → Sign In / Providers* e desative **Allow new users to sign up**. Assim, só quem você cadastrou consegue entrar e ver os dados.
4. **Publicar** — se o repositório estiver no GitHub Pages, o app fica em `https://<seu-usuario>.github.io/<repositório>/gestao/`.

Todos os usuários logados enxergam e editam os mesmos dados (todas as empresas).

## Modo local (teste)

Abra `gestao/index.html?local=1` para testar sem login: os dados ficam só naquele navegador. Use o backup em JSON para levar os dados para o modo online depois (aba *Empresas e backup → Importar backup*).
