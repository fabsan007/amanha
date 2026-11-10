-- AMANHÃ 2.0 — execute no SQL Editor do projeto Supabase.
-- Aplique inicialmente em ambiente de testes. Não apaga tabelas existentes.
create extension if not exists pgcrypto;
create table if not exists public.admin_users(user_id uuid primary key references auth.users(id) on delete cascade,created_at timestamptz not null default now());
create table if not exists public.financial_diagnostics(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,
 monthly_income numeric(14,2) not null check(monthly_income>=0),monthly_expenses numeric(14,2) not null check(monthly_expenses>=0),
 liquid_assets numeric(14,2) not null check(liquid_assets>=0),total_debt numeric(14,2) not null check(total_debt>=0),
 emergency_savings numeric(14,2) not null check(emergency_savings>=0),existing_insurance numeric(14,2) not null check(existing_insurance>=0),
 dependents integer not null check(dependents between 0 and 30),reserve_months integer not null check(reserve_months in (3,6,12)),
 protection_years integer not null check(protection_years between 1 and 40),challenge text not null,
 current_habits text not null,share_with_advisor boolean not null default false,created_at timestamptz not null default now());
create index if not exists diagnostics_user_created_idx on public.financial_diagnostics(user_id,created_at desc);
create table if not exists public.financial_goals(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,
 title text not null,target_amount numeric(14,2) not null check(target_amount>0),months integer not null check(months between 1 and 600),
 saved_amount numeric(14,2) not null check(saved_amount>=0),monthly_contribution numeric(14,2) not null check(monthly_contribution>=0),created_at timestamptz not null default now());
create table if not exists public.monthly_checkins(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,
 month date not null,saved_amount numeric(14,2) not null check(saved_amount>=0),notes text,created_at timestamptz not null default now(),unique(user_id,month));
create table if not exists public.advisor_notes(id uuid primary key default gen_random_uuid(),client_id uuid not null references auth.users(id) on delete cascade,
 admin_id uuid not null references auth.users(id),note text not null,created_at timestamptz not null default now());

alter table public.admin_users enable row level security;
alter table public.financial_diagnostics enable row level security;
alter table public.financial_goals enable row level security;
alter table public.monthly_checkins enable row level security;
alter table public.advisor_notes enable row level security;

-- Permissões dos clientes: somente seus próprios registros.
create policy "admin_self_read" on public.admin_users for select to authenticated using(user_id=(select auth.uid()));
create policy "diag_self_read" on public.financial_diagnostics for select to authenticated using(user_id=(select auth.uid()));
create policy "diag_self_insert" on public.financial_diagnostics for insert to authenticated with check(user_id=(select auth.uid()));
create policy "diag_self_update" on public.financial_diagnostics for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy "goals_self_read" on public.financial_goals for select to authenticated using(user_id=(select auth.uid()));
create policy "goals_self_insert" on public.financial_goals for insert to authenticated with check(user_id=(select auth.uid()));
create policy "goals_self_update" on public.financial_goals for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy "checkins_self_read" on public.monthly_checkins for select to authenticated using(user_id=(select auth.uid()));
create policy "checkins_self_insert" on public.monthly_checkins for insert to authenticated with check(user_id=(select auth.uid()));
create policy "checkins_self_update" on public.monthly_checkins for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));

-- Função auxiliar SECURITY DEFINER restrita, sem parâmetro de usuário arbitrário.
create or replace function public.is_amanha_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.admin_users where user_id=(select auth.uid()));
$$;
revoke all on function public.is_amanha_admin() from public,anon;
grant execute on function public.is_amanha_admin() to authenticated;

-- Consentimento vigente = diagnóstico mais recente do cliente, e não histórico antigo.
create or replace function public.amanha_client_consented(p_user uuid) returns boolean language sql stable security definer set search_path='' as $$
 select coalesce((select share_with_advisor from public.financial_diagnostics where user_id=p_user order by created_at desc,id desc limit 1),false)
$$;
revoke all on function public.amanha_client_consented(uuid) from public,anon;
grant execute on function public.amanha_client_consented(uuid) to authenticated;

create policy "goals_admin_read_consented" on public.financial_goals for select to authenticated
 using(public.is_amanha_admin() and public.amanha_client_consented(user_id));
create policy "notes_admin_read_consented" on public.advisor_notes for select to authenticated
 using(public.is_amanha_admin() and public.amanha_client_consented(client_id));
create policy "notes_admin_insert_consented" on public.advisor_notes for insert to authenticated
 with check(public.is_amanha_admin() and admin_id=(select auth.uid()) and public.amanha_client_consented(client_id));

-- Visão de atendimento: somente último diagnóstico de quem autorizou e usuário é administrador.
create or replace function public.admin_client_overview()
returns table(user_id uuid,email text,full_name text,challenge text,current_habits text,
 monthly_income numeric,monthly_expenses numeric,total_debt numeric,reserve_gap numeric,protection_gap numeric)
language plpgsql stable security definer set search_path='' as $$
begin
 if not public.is_amanha_admin() then raise exception 'Acesso não autorizado'; end if;
 return query
 select d.user_id,u.email::text,coalesce(u.raw_user_meta_data->>'full_name','')::text,
 d.challenge,d.current_habits,d.monthly_income,d.monthly_expenses,d.total_debt,
 greatest(0,d.monthly_expenses*d.reserve_months-d.emergency_savings),
 greatest(0,d.monthly_expenses*12*d.protection_years+d.total_debt-d.liquid_assets-d.existing_insurance)
 from (select distinct on (x.user_id) x.* from public.financial_diagnostics x order by x.user_id,x.created_at desc,x.id desc) d
 join auth.users u on u.id=d.user_id where d.share_with_advisor=true;
end $$;
revoke all on function public.admin_client_overview() from public,anon;
grant execute on function public.admin_client_overview() to authenticated;

revoke all on public.admin_users,public.financial_diagnostics,public.financial_goals,public.monthly_checkins,public.advisor_notes from anon;
grant select on public.admin_users to authenticated;
grant select,insert,update on public.financial_diagnostics,public.financial_goals,public.monthly_checkins to authenticated;
grant select,insert on public.advisor_notes to authenticated;

-- APÓS criar seu usuário no cadastro, conceda acesso administrativo pelo SQL Editor:
-- insert into public.admin_users(user_id) values ('COLE_AQUI_O_UUID_DO_SEU_USUARIO');
-- NÃO conceda permissão de administrador a partir do navegador ou por cadastro público.
