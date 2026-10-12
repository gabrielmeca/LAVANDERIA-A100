-- ==========================================================
-- Controle Financeiro — estrutura do banco (Supabase / PostgreSQL)
-- Rode em: Supabase > SQL Editor > New query > Run
-- É seguro rodar de novo (também serve para ATUALIZAR uma instalação antiga):
-- só cria o que não existe e nunca apaga dados.
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

-- Categorias configuráveis (empresa_id nulo = compartilhada)
create table if not exists public.categorias (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  empresa_id uuid references public.empresas(id) on delete cascade,
  nome text not null,
  tipo text not null default 'ambos' check (tipo in ('pagar','receber','ambos')),
  grupo text,
  ativo boolean not null default true
);

-- Formas de compra (lista editável usada nas contas a pagar)
create table if not exists public.formas_compra (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  nome text not null unique,
  ativo boolean not null default true
);
alter table public.lancamentos add column if not exists forma_compra text;

-- Técnicos que realizam os atendimentos (lista editável)
create table if not exists public.tecnicos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  nome text not null unique,
  telefone text,
  ativo boolean not null default true
);

-- Serviços realizados: cada um gera automaticamente uma conta a receber
create table if not exists public.atendimentos (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  data date not null default current_date,
  parceiro_id uuid references public.parceiros(id) on delete set null,
  descricao text not null,
  valor numeric(14,2) not null default 0,
  tecnico_id uuid references public.tecnicos(id) on delete set null,
  orcamento text,
  laudo boolean not null default false,
  forma_pagamento text,
  vencimento date,
  ja_recebido boolean not null default false,
  servico_id uuid references public.servicos(id) on delete set null,
  observacao text,
  lancamento_id uuid references public.lancamentos(id) on delete set null
);
create index if not exists atendimentos_empresa_data on public.atendimentos (empresa_id, data);

-- Níveis de acesso: permissoes = {"modulo": ["ver","criar",...], ...}
create table if not exists public.niveis_acesso (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  nome text not null unique,
  descricao text,
  permissoes jsonb not null default '{}'::jsonb
);

-- Perfil de cada usuário do app (criado automaticamente no cadastro)
create table if not exists public.perfis (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  email text,
  nome text,
  ativo boolean not null default false,
  admin boolean not null default false,
  nivel_id uuid references public.niveis_acesso(id) on delete set null,
  empresas uuid[] -- vazio/nulo = todas as empresas
);

-- ----------------------------------------------------------
-- Funções de permissão (usadas pelas regras de segurança)
-- ----------------------------------------------------------
create or replace function public.usuario_ativo() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select ativo from perfis where user_id = auth.uid()), false)
$$;

create or replace function public.eh_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select ativo and admin from perfis where user_id = auth.uid()), false)
$$;

create or replace function public.pode(modulo text, acao text) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((
    select p.ativo and (p.admin or coalesce((n.permissoes -> modulo) ? acao, false))
    from perfis p left join niveis_acesso n on n.id = p.nivel_id
    where p.user_id = auth.uid()
  ), false)
$$;

create or replace function public.ve_empresa(emp uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((
    select p.ativo and (emp is null or p.admin or p.empresas is null or cardinality(p.empresas) = 0 or emp = any(p.empresas))
    from perfis p where p.user_id = auth.uid()
  ), false)
$$;

create or replace function public.modulo_conta(tipo text) returns text
language sql immutable as $$
  select case when tipo = 'pagar' then 'contas_pagar' else 'contas_receber' end
$$;

-- Quem só pode "dar baixa" não consegue alterar outros campos da conta
create or replace function public.lancamentos_guarda() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or current_setting('app.ignorar_guarda', true) = 'on' then return new; end if;
  if pode(modulo_conta(old.tipo), 'editar') then return new; end if;
  if (new.empresa_id, new.tipo, new.descricao, new.parceiro_id, new.servico_id, new.categoria, new.valor, new.vencimento,
      new.observacao, new.grupo_parcela, new.parcela_num, new.parcela_total, new.forma_compra)
     is distinct from
     (old.empresa_id, old.tipo, old.descricao, old.parceiro_id, old.servico_id, old.categoria, old.valor, old.vencimento,
      old.observacao, old.grupo_parcela, old.parcela_num, old.parcela_total, old.forma_compra)
     or new.status = 'cancelado' or old.status = 'cancelado' then
    raise exception 'Sem permissão para editar este lançamento (apenas registrar pagamento/recebimento).';
  end if;
  return new;
end $$;
drop trigger if exists lancamentos_guarda on public.lancamentos;
create trigger lancamentos_guarda before update on public.lancamentos
  for each row execute function public.lancamentos_guarda();

-- Renomear categoria também atualiza as contas que usam o nome antigo
create or replace function public.renomear_categoria(antigo text, novo text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not pode('categorias', 'editar') then raise exception 'Sem permissão para editar categorias.'; end if;
  perform set_config('app.ignorar_guarda', 'on', true);
  update lancamentos set categoria = novo where categoria = antigo;
end $$;

-- Renomear forma de compra também atualiza as contas
create or replace function public.renomear_forma_compra(antigo text, novo text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not pode('categorias', 'editar') then raise exception 'Sem permissão para editar formas de compra.'; end if;
  perform set_config('app.ignorar_guarda', 'on', true);
  update lancamentos set forma_compra = novo where forma_compra = antigo;
end $$;

-- Serviço realizado -> conta a receber (criada ao lançar o serviço e atualizada ao editar)
create or replace function public.atendimentos_sync() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  lid uuid;
  descr text := new.descricao || coalesce(' · Orç. ' || nullif(trim(new.orcamento), ''), '');
  obs text := concat_ws(' · ', 'Técnico: ' || (select nome from tecnicos where id = new.tecnico_id),
                        'Laudo: ' || case when new.laudo then 'Sim' else 'Não' end, nullif(trim(new.observacao), ''));
begin
  perform set_config('app.ignorar_guarda', 'on', true);
  if tg_op = 'INSERT' then
    insert into lancamentos (empresa_id, tipo, descricao, parceiro_id, servico_id, categoria, valor, vencimento,
                             status, pagamento, valor_pago, forma_pagamento, observacao)
    values (new.empresa_id, 'receber', descr, new.parceiro_id, new.servico_id, 'Serviços', new.valor, coalesce(new.vencimento, new.data),
            case when new.ja_recebido then 'pago' else 'pendente' end,
            case when new.ja_recebido then new.data end, case when new.ja_recebido then new.valor end,
            new.forma_pagamento, obs)
    returning id into lid;
    new.lancamento_id := lid;
  elsif new.lancamento_id is not null then
    update lancamentos set empresa_id = new.empresa_id, descricao = descr, parceiro_id = new.parceiro_id, servico_id = new.servico_id,
      valor = new.valor, vencimento = coalesce(new.vencimento, new.data), forma_pagamento = new.forma_pagamento, observacao = obs
    where id = new.lancamento_id;
  end if;
  perform set_config('app.ignorar_guarda', 'off', true);
  return new;
end $$;
drop trigger if exists atendimentos_sync on public.atendimentos;
create trigger atendimentos_sync before insert or update on public.atendimentos
  for each row execute function public.atendimentos_sync();

-- Excluir o serviço exclui a conta a receber, se ela ainda não foi recebida
create or replace function public.atendimentos_apaga_conta() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  delete from lancamentos where id = old.lancamento_id and status <> 'pago';
  return old;
end $$;
drop trigger if exists atendimentos_apaga_conta on public.atendimentos;
create trigger atendimentos_apaga_conta after delete on public.atendimentos
  for each row execute function public.atendimentos_apaga_conta();

-- Novo cadastro (pelo app ou pelo painel) ganha um perfil "aguardando liberação".
-- Se ainda não existe nenhum administrador, o primeiro usuário vira administrador.
create or replace function public.novo_usuario() returns trigger
language plpgsql security definer set search_path = public as $$
declare tem_admin boolean;
begin
  select exists(select 1 from perfis where admin and ativo) into tem_admin;
  insert into perfis (user_id, email, nome, ativo, admin)
  values (new.id, new.email, coalesce(new.raw_user_meta_data ->> 'nome', split_part(new.email, '@', 1)), not tem_admin, not tem_admin)
  on conflict (user_id) do nothing;
  return new;
end $$;
drop trigger if exists ao_criar_usuario on auth.users;
create trigger ao_criar_usuario after insert on auth.users
  for each row execute function public.novo_usuario();

-- Usuários que já existiam antes desta atualização continuam com acesso total (administradores)
insert into public.perfis (user_id, email, nome, ativo, admin)
select u.id, u.email, split_part(u.email, '@', 1), true, true
from auth.users u
where not exists (select 1 from public.perfis p where p.user_id = u.id);

-- ----------------------------------------------------------
-- Níveis de acesso e categorias iniciais (só na primeira vez)
-- ----------------------------------------------------------
insert into public.niveis_acesso (nome, descricao, permissoes) values
 ('Financeiro', 'Contas a pagar e receber, cadastros e importação',
  '{"dashboard":["ver"],"contas_receber":["ver","criar","editar","baixar","excluir","exportar"],"contas_pagar":["ver","criar","editar","baixar","excluir","exportar"],"parceiros":["ver","criar","editar","excluir"],"servicos":["ver","criar","editar"],"categorias":["ver","criar","editar"],"estoque":["ver"],"empresas":["ver"],"importar":["usar"]}'),
 ('Atendimento', 'Lança e recebe contas de clientes, sem ver contas a pagar',
  '{"contas_receber":["ver","criar","baixar"],"parceiros":["ver","criar","editar"],"servicos":["ver"],"estoque":["ver","movimentar"]}'),
 ('Estoque', 'Controle de produtos e movimentações',
  '{"estoque":["ver","criar","editar","movimentar"],"parceiros":["ver"]}'),
 ('Somente consulta', 'Vê tudo, não altera nada',
  '{"dashboard":["ver"],"contas_receber":["ver"],"contas_pagar":["ver"],"parceiros":["ver"],"servicos":["ver"],"categorias":["ver"],"estoque":["ver"],"empresas":["ver"]}')
on conflict (nome) do nothing;

insert into public.categorias (nome, tipo, grupo)
select c.nome, c.tipo, c.grupo from (values
  ('Lavagem','receber','Receitas'), ('Secagem','receber','Receitas'), ('Combos','receber','Receitas'),
  ('Lavanderia assistida','receber','Receitas'), ('Venda de produtos','receber','Receitas'), ('Serviços','receber','Receitas'), ('Outras receitas','receber','Receitas'),
  ('Produtos químicos','pagar','Insumos'), ('Essências','pagar','Insumos'), ('Embalagens','pagar','Insumos'), ('Compras de estoque','pagar','Insumos'),
  ('Aluguel','pagar','Despesas operacionais'), ('Água','pagar','Despesas operacionais'), ('Energia','pagar','Despesas operacionais'),
  ('Internet','pagar','Despesas operacionais'), ('Contabilidade','pagar','Despesas operacionais'), ('Manutenção','pagar','Despesas operacionais'),
  ('Salários','pagar','Pessoal'), ('Simples Nacional','pagar','Tributos'), ('Taxas municipais','pagar','Tributos'),
  ('Tarifas bancárias','pagar','Despesas financeiras'), ('Juros','pagar','Despesas financeiras'),
  ('Parcela de máquinas','pagar','Investimentos'), ('Novos equipamentos','pagar','Investimentos'), ('Outras despesas','pagar','Outras')
) as c(nome, tipo, grupo)
where not exists (select 1 from public.categorias);

insert into public.formas_compra (nome)
select f.nome from (values ('À vista'), ('A prazo (boleto)'), ('Cartão de crédito'), ('Pix'), ('Transferência')) as f(nome)
where not exists (select 1 from public.formas_compra);

-- ----------------------------------------------------------
-- Regras de segurança (RLS): cada usuário só faz o que o nível dele permite
-- ----------------------------------------------------------
do $$
declare t text; pol record;
begin
  foreach t in array array['empresas','parceiros','servicos','lancamentos','produtos','movimentos_estoque','categorias','formas_compra','tecnicos','atendimentos','niveis_acesso','perfis'] loop
    execute format('alter table public.%I enable row level security', t);
    for pol in select policyname from pg_policies where schemaname = 'public' and tablename = t loop
      execute format('drop policy %I on public.%I', pol.policyname, t);
    end loop;
  end loop;
end $$;

-- empresas
create policy sel on public.empresas for select to authenticated using (ve_empresa(id));
create policy ins on public.empresas for insert to authenticated with check (pode('empresas','criar'));
create policy upd on public.empresas for update to authenticated using (ve_empresa(id) and pode('empresas','editar'));
create policy del on public.empresas for delete to authenticated using (ve_empresa(id) and pode('empresas','excluir'));

-- cadastros compartilhados: todos os usuários ativos leem (para preencher as telas), só quem pode altera
create policy sel on public.parceiros for select to authenticated using (ve_empresa(empresa_id));
create policy ins on public.parceiros for insert to authenticated with check (ve_empresa(empresa_id) and pode('parceiros','criar'));
create policy upd on public.parceiros for update to authenticated using (ve_empresa(empresa_id) and pode('parceiros','editar')) with check (ve_empresa(empresa_id));
create policy del on public.parceiros for delete to authenticated using (ve_empresa(empresa_id) and pode('parceiros','excluir'));

create policy sel on public.servicos for select to authenticated using (ve_empresa(empresa_id));
create policy ins on public.servicos for insert to authenticated with check (ve_empresa(empresa_id) and pode('servicos','criar'));
create policy upd on public.servicos for update to authenticated using (ve_empresa(empresa_id) and pode('servicos','editar')) with check (ve_empresa(empresa_id));
create policy del on public.servicos for delete to authenticated using (ve_empresa(empresa_id) and pode('servicos','excluir'));

create policy sel on public.categorias for select to authenticated using (ve_empresa(empresa_id));
create policy ins on public.categorias for insert to authenticated with check (ve_empresa(empresa_id) and pode('categorias','criar'));
create policy upd on public.categorias for update to authenticated using (ve_empresa(empresa_id) and pode('categorias','editar')) with check (ve_empresa(empresa_id));
create policy del on public.categorias for delete to authenticated using (ve_empresa(empresa_id) and pode('categorias','excluir'));

-- contas: permissão separada para "a pagar" e "a receber"
create policy sel on public.lancamentos for select to authenticated using (ve_empresa(empresa_id) and pode(modulo_conta(tipo),'ver'));
create policy ins on public.lancamentos for insert to authenticated with check (ve_empresa(empresa_id) and pode(modulo_conta(tipo),'criar'));
create policy upd on public.lancamentos for update to authenticated
  using (ve_empresa(empresa_id) and (pode(modulo_conta(tipo),'editar') or pode(modulo_conta(tipo),'baixar')))
  with check (ve_empresa(empresa_id) and (pode(modulo_conta(tipo),'editar') or pode(modulo_conta(tipo),'baixar')));
create policy del on public.lancamentos for delete to authenticated using (ve_empresa(empresa_id) and pode(modulo_conta(tipo),'excluir'));

-- estoque
create policy sel on public.produtos for select to authenticated using (ve_empresa(empresa_id) and pode('estoque','ver'));
create policy ins on public.produtos for insert to authenticated with check (ve_empresa(empresa_id) and pode('estoque','criar'));
create policy upd on public.produtos for update to authenticated using (ve_empresa(empresa_id) and (pode('estoque','editar') or pode('estoque','movimentar'))) with check (ve_empresa(empresa_id));
create policy del on public.produtos for delete to authenticated using (ve_empresa(empresa_id) and pode('estoque','excluir'));

create policy sel on public.movimentos_estoque for select to authenticated using (ve_empresa(empresa_id) and pode('estoque','ver'));
create policy ins on public.movimentos_estoque for insert to authenticated with check (ve_empresa(empresa_id) and (pode('estoque','movimentar') or pode('estoque','criar')));
create policy del on public.movimentos_estoque for delete to authenticated using (ve_empresa(empresa_id) and pode('estoque','excluir'));

-- formas de compra: todos os usuários ativos leem; altera quem pode editar categorias
create policy sel on public.formas_compra for select to authenticated using (usuario_ativo());
create policy ins on public.formas_compra for insert to authenticated with check (pode('categorias','criar'));
create policy upd on public.formas_compra for update to authenticated using (pode('categorias','editar'));
create policy del on public.formas_compra for delete to authenticated using (pode('categorias','excluir'));

-- serviços realizados e técnicos: permissão da área "Serviços"
create policy sel on public.atendimentos for select to authenticated using (ve_empresa(empresa_id) and pode('servicos','ver'));
create policy ins on public.atendimentos for insert to authenticated with check (ve_empresa(empresa_id) and pode('servicos','criar'));
create policy upd on public.atendimentos for update to authenticated using (ve_empresa(empresa_id) and pode('servicos','editar')) with check (ve_empresa(empresa_id));
create policy del on public.atendimentos for delete to authenticated using (ve_empresa(empresa_id) and pode('servicos','excluir'));

create policy sel on public.tecnicos for select to authenticated using (usuario_ativo());
create policy ins on public.tecnicos for insert to authenticated with check (pode('servicos','criar'));
create policy upd on public.tecnicos for update to authenticated using (pode('servicos','editar'));
create policy del on public.tecnicos for delete to authenticated using (pode('servicos','excluir'));

-- níveis e perfis: só administradores alteram
create policy sel on public.niveis_acesso for select to authenticated using (usuario_ativo());
create policy ins on public.niveis_acesso for insert to authenticated with check (eh_admin());
create policy upd on public.niveis_acesso for update to authenticated using (eh_admin());
create policy del on public.niveis_acesso for delete to authenticated using (eh_admin());

create policy sel on public.perfis for select to authenticated using (user_id = auth.uid() or eh_admin());
create policy upd on public.perfis for update to authenticated using (eh_admin());
create policy del on public.perfis for delete to authenticated using (eh_admin() and user_id <> auth.uid());

-- ----------------------------------------------------------
-- Tempo real: outras telas abertas atualizam sozinhas
-- ----------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['empresas','parceiros','servicos','lancamentos','produtos','movimentos_estoque','categorias','formas_compra','tecnicos','atendimentos','niveis_acesso','perfis'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
