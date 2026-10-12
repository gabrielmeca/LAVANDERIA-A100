-- ==========================================================
-- Controle Financeiro — estrutura do banco (Supabase / PostgreSQL)
-- Rode este arquivo UMA vez em: Supabase > SQL Editor > New query > Run
-- É seguro rodar de novo: só cria o que ainda não existe.
-- ==========================================================

create extension if not exists pgcrypto;

-- Empresas geridas
create table if not exists public.empresas (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  nome text not null,
  documento text
);

-- Clientes e fornecedores (empresa_id nulo = compartilhado entre todas as empresas)
create table if not exists public.parceiros (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  empresa_id uuid references public.empresas(id) on delete cascade,
  nome text not null,
  tipo text not null default 'cliente' check (tipo in ('cliente','fornecedor','ambos')),
  documento text,
  telefone text,
  email text,
  observacao text
);

-- Serviços prestados (empresa_id nulo = compartilhado)
create table if not exists public.servicos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  empresa_id uuid references public.empresas(id) on delete cascade,
  nome text not null,
  preco numeric(14,2) not null default 0,
  descricao text
);

-- Contas a pagar e a receber
create table if not exists public.lancamentos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  tipo text not null check (tipo in ('pagar','receber')),
  descricao text not null,
  parceiro_id uuid references public.parceiros(id) on delete set null,
  servico_id uuid references public.servicos(id) on delete set null,
  categoria text,
  valor numeric(14,2) not null default 0,
  vencimento date not null,
  status text not null default 'pendente' check (status in ('pendente','pago','cancelado')),
  pagamento date,
  valor_pago numeric(14,2),
  forma_pagamento text,
  grupo_parcela text,
  parcela_num int,
  parcela_total int,
  observacao text
);
create index if not exists lancamentos_empresa_venc on public.lancamentos (empresa_id, vencimento);

-- Produtos em estoque
create table if not exists public.produtos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  nome text not null,
  sku text,
  unidade text not null default 'un',
  estoque_minimo numeric(14,3) not null default 0,
  custo numeric(14,2) not null default 0,
  preco_venda numeric(14,2) not null default 0
);

-- Movimentações de estoque (entrada soma, saída subtrai, ajuste soma o valor com sinal)
create table if not exists public.movimentos_estoque (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  produto_id uuid not null references public.produtos(id) on delete cascade,
  tipo text not null check (tipo in ('entrada','saida','ajuste')),
  quantidade numeric(14,3) not null,
  valor_unitario numeric(14,2) not null default 0,
  data date not null default current_date,
  observacao text,
  lancamento_id uuid references public.lancamentos(id) on delete set null
);
create index if not exists movimentos_produto on public.movimentos_estoque (produto_id);

-- ----------------------------------------------------------
-- Segurança: só usuários logados (Supabase Auth) leem e gravam
-- ----------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['empresas','parceiros','servicos','lancamentos','produtos','movimentos_estoque'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "logados_tudo" on public.%I', t);
    execute format('create policy "logados_tudo" on public.%I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- ----------------------------------------------------------
-- Tempo real: outras telas abertas atualizam sozinhas
-- ----------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['empresas','parceiros','servicos','lancamentos','produtos','movimentos_estoque'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
