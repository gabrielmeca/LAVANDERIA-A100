# Controle Financeiro

App web de **contas a pagar e a receber** para várias empresas, com clientes/fornecedores, serviços, **controle de estoque** e **dashboards**. Tudo fica salvo online no Supabase: dá para acessar e alterar de qualquer computador ou celular, e as telas abertas se atualizam sozinhas quando alguém muda algo.

Arquivo do app: `gestao/index.html` (uma única página, sem build).
O controle de caixa antigo (`index.html` na raiz) continua funcionando como antes.

## O que tem

| Aba | Recursos |
|---|---|
| **Dashboard** | Resultado, recebido, pago, a receber/a pagar em aberto (com vencidos), valor em estoque; gráficos de fluxo de caixa mensal, resultado mensal, previsão das próximas 12 semanas, receita por serviço, maiores clientes, despesas por categoria e comparativo entre empresas. |
| **Contas a pagar / receber** | Lançamentos com cliente/fornecedor, serviço, categoria, parcelas, baixa e estorno. Filtros por tipo, situação, cliente, serviço, categoria, datas e busca. Exportação em CSV. |
| **Clientes e fornecedores** | Cadastro com totais recebidos e em aberto. |
| **Serviços** | Preço padrão e faturamento por serviço. |
| **Estoque** | Produtos, saldo, mínimo, entradas/saídas/ajustes, geração automática de conta. |
| **Categorias** | Categorias de receita e despesa, organizadas por grupo. Criar, renomear (as contas acompanham), desativar e excluir. |
| **Importar** | Modelos de planilha (Excel/CSV) para contas, clientes/fornecedores, serviços, produtos, movimentações e categorias. Mostra a conferência linha a linha antes de gravar. |
| **Empresas e backup** | Várias empresas; backup em JSON. |
| **Usuários e acessos** | (só administradores) Criar usuários, liberar quem se cadastrou e criar **níveis de acesso**. |

### Níveis de acesso

Cada nível define, para cada área (Dashboard, Contas a receber, Contas a pagar, Clientes, Serviços, Estoque, Categorias, Empresas, Importar, Backup), o que a pessoa pode fazer: **ver, criar, editar, dar baixa, movimentar, excluir, exportar**. Cada usuário recebe um nível e a lista de empresas que pode acessar. Administradores podem tudo.

As regras valem **no banco de dados** (Supabase), não só na tela: mesmo que alguém tente burlar o app, o servidor recusa.

Níveis prontos (podem ser editados): *Financeiro*, *Atendimento*, *Estoque* e *Somente consulta*.

## Configuração

### Primeira vez ou atualização

1. No painel do Supabase: **SQL Editor → New query**, cole todo o conteúdo de [`schema.sql`](schema.sql) e clique em **Run**. O script pode ser rodado de novo sempre que o app for atualizado: ele só cria o que falta e não apaga dados.
   - Quem já tinha usuário antes desta versão vira **administrador** automaticamente.
   - Num projeto novo, o **primeiro** usuário que se cadastrar vira administrador.
2. Em **Authentication → Sign In / Providers**:
   - deixe **Allow new users to sign up** **ligado**: é assim que o app cria usuários. Quem se cadastrar sozinho fica "aguardando liberação" e não vê nada até um administrador liberar;
   - em **Email**, desligue **Confirm email** se quiser que os usuários criados pelo app entrem na hora, sem precisar clicar no link do e-mail.

### Criar usuários

Entre como administrador → aba **Usuários e acessos** → **+ Novo usuário**: nome, e-mail, senha inicial, nível de acesso e empresas. Cada pessoa pode trocar a própria senha no botão **Minha senha**.

Para tirar o acesso de alguém, use **Desativar**. Para apagar a conta de vez: Supabase → Authentication → Users.

### Publicar

Se o repositório estiver no GitHub Pages, o app fica em `https://<seu-usuario>.github.io/<repositório>/gestao/`.

## Modo local (teste)

Abra `gestao/index.html?local=1` para testar sem login: os dados ficam só naquele navegador e não há controle de usuários. Use o backup em JSON para levar os dados para o modo online depois.
