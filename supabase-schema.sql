-- ============================================
-- MINHA JORNADA — Schema Supabase
-- Cole isso no SQL Editor do seu projeto Supabase
-- ============================================

-- Extensão para UUIDs
create extension if not exists "uuid-ossp";

-- ============================================
-- TABELA: areas_vida
-- As 6 áreas fixas da vida do usuário
-- ============================================
create table areas_vida (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  nome text not null,
  cor text not null default '#7F77DD',
  icone text not null default '⭐',
  ordem int not null default 0,
  ativo boolean default true,
  created_at timestamptz default now()
);

-- ============================================
-- TABELA: tarefas
-- Tarefas recorrentes ou únicas por área
-- ============================================
create table tarefas (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  area_id uuid references areas_vida(id) on delete cascade not null,
  titulo text not null,
  descricao text,
  xp_valor int not null default 10,
  recorrencia text default 'diaria', -- diaria | semanal | unica
  dias_semana int[] default '{1,2,3,4,5,6,7}', -- 1=seg ... 7=dom
  ativo boolean default true,
  created_at timestamptz default now()
);

-- ============================================
-- TABELA: registros_diarios
-- Cada tarefa marcada num dia específico
-- ============================================
create table registros_diarios (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  tarefa_id uuid references tarefas(id) on delete cascade not null,
  data date not null default current_date,
  status text not null default 'pendente', -- pendente | feito | pulado
  motivo_nao_feito text,
  xp_ganho int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, tarefa_id, data)
);

-- ============================================
-- TABELA: metas_anuais
-- Metas do ano com progresso
-- ============================================
create table metas_anuais (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  area_id uuid references areas_vida(id) on delete set null,
  titulo text not null,
  descricao text,
  ano int not null default extract(year from current_date)::int,
  meta_valor numeric,
  valor_atual numeric default 0,
  unidade text, -- 'livros', 'sessões', 'R$', '%', etc.
  concluida boolean default false,
  data_conclusao date,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- TABELA: perfil_usuario
-- XP, nível, streak
-- ============================================
create table perfil_usuario (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text,
  xp_total int default 0,
  nivel int default 1,
  streak_atual int default 0,
  streak_maximo int default 0,
  ultimo_dia_ativo date,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- FUNÇÃO: calcular nível a partir do XP
-- A cada 1000 XP sobe um nível
-- ============================================
create or replace function calcular_nivel(xp int)
returns int as $$
begin
  return floor(xp / 1000) + 1;
end;
$$ language plpgsql;

-- ============================================
-- FUNÇÃO: atualizar XP e streak após registro
-- ============================================
create or replace function atualizar_perfil_apos_registro()
returns trigger as $$
declare
  v_xp_delta int;
  v_user_id uuid;
  v_data date;
  v_ontem date;
  v_ultimo date;
begin
  v_user_id := NEW.user_id;
  v_data := NEW.data;
  v_ontem := current_date - interval '1 day';
  
  -- XP: soma se ficou feito, subtrai se voltou de feito
  if NEW.status = 'feito' and (OLD.status is null or OLD.status != 'feito') then
    v_xp_delta := NEW.xp_ganho;
  elsif NEW.status != 'feito' and OLD.status = 'feito' then
    v_xp_delta := -OLD.xp_ganho;
  else
    v_xp_delta := 0;
  end if;

  -- Atualiza XP e nível
  if v_xp_delta != 0 then
    update perfil_usuario
    set 
      xp_total = greatest(0, xp_total + v_xp_delta),
      nivel = calcular_nivel(greatest(0, xp_total + v_xp_delta)),
      updated_at = now()
    where id = v_user_id;
  end if;

  -- Atualiza streak se for hoje
  if NEW.status = 'feito' and v_data = current_date then
    select ultimo_dia_ativo into v_ultimo from perfil_usuario where id = v_user_id;
    
    if v_ultimo = v_ontem then
      -- continuou o streak
      update perfil_usuario set
        streak_atual = streak_atual + 1,
        streak_maximo = greatest(streak_maximo, streak_atual + 1),
        ultimo_dia_ativo = current_date,
        updated_at = now()
      where id = v_user_id;
    elsif v_ultimo < v_ontem or v_ultimo is null then
      -- quebrou ou começou o streak
      update perfil_usuario set
        streak_atual = 1,
        streak_maximo = greatest(streak_maximo, 1),
        ultimo_dia_ativo = current_date,
        updated_at = now()
      where id = v_user_id;
    end if;
  end if;

  return NEW;
end;
$$ language plpgsql security definer;

-- Trigger no registro
create trigger on_registro_update
  after insert or update on registros_diarios
  for each row execute function atualizar_perfil_apos_registro();

-- ============================================
-- FUNÇÃO: criar perfil + áreas padrão no signup
-- ============================================
create or replace function criar_perfil_novo_usuario()
returns trigger as $$
begin
  -- Cria perfil
  insert into perfil_usuario (id, nome)
  values (NEW.id, split_part(NEW.email, '@', 1));

  -- Cria as 6 áreas padrão
  insert into areas_vida (user_id, nome, cor, icone, ordem) values
    (NEW.id, 'Estudos',      '#7F77DD', '📚', 1),
    (NEW.id, 'Trabalho',     '#1D9E75', '💼', 2),
    (NEW.id, 'Espiritual',   '#EF9F27', '✝️',  3),
    (NEW.id, 'Saúde Física', '#D85A30', '🏋️', 4),
    (NEW.id, 'Saúde Mental', '#378ADD', '🧘', 5),
    (NEW.id, 'Lazer',        '#D4537E', '🎮', 6);

  return NEW;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function criar_perfil_novo_usuario();

-- ============================================
-- ROW LEVEL SECURITY — cada user vê só os seus
-- ============================================
alter table areas_vida enable row level security;
alter table tarefas enable row level security;
alter table registros_diarios enable row level security;
alter table metas_anuais enable row level security;
alter table perfil_usuario enable row level security;

create policy "user_own_areas" on areas_vida for all using (auth.uid() = user_id);
create policy "user_own_tarefas" on tarefas for all using (auth.uid() = user_id);
create policy "user_own_registros" on registros_diarios for all using (auth.uid() = user_id);
create policy "user_own_metas" on metas_anuais for all using (auth.uid() = user_id);
create policy "user_own_perfil" on perfil_usuario for all using (auth.uid() = id);

-- ============================================
-- TABELA: livros
-- Controle de leitura mensal
-- ============================================
create table livros (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  titulo text not null,
  autor text,
  total_paginas int not null,
  paginas_lidas int default 0,
  data_inicio date not null default current_date,
  data_meta date not null, -- geralmente 30 dias depois
  concluido boolean default false,
  data_conclusao date,
  mes_referencia text, -- ex: '2025-04'
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- TABELA: registros_leitura
-- Quantas páginas leu por dia
-- ============================================
create table registros_leitura (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  livro_id uuid references livros(id) on delete cascade not null,
  data date not null default current_date,
  paginas_lidas_hoje int not null default 0,
  pagina_atual int not null,
  nota text, -- comentário opcional sobre a leitura do dia
  created_at timestamptz default now(),
  unique(user_id, livro_id, data)
);

-- RLS
alter table livros enable row level security;
alter table registros_leitura enable row level security;
create policy "user_own_livros" on livros for all using (auth.uid() = user_id);
create policy "user_own_leitura" on registros_leitura for all using (auth.uid() = user_id);

-- Função: atualizar paginas_lidas no livro após registro
create or replace function atualizar_livro_apos_leitura()
returns trigger as $$
begin
  update livros set
    paginas_lidas = NEW.pagina_atual,
    concluido = (NEW.pagina_atual >= total_paginas),
    data_conclusao = case when NEW.pagina_atual >= total_paginas then current_date else null end,
    updated_at = now()
  where id = NEW.livro_id;
  return NEW;
end;
$$ language plpgsql security definer;

create trigger on_leitura_registrada
  after insert or update on registros_leitura
  for each row execute function atualizar_livro_apos_leitura();
