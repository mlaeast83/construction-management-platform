-- Initial core schema for the independent construction management platform.
-- Apply only to the dedicated Supabase project after verifying its identity.
-- Organization onboarding and membership writes are intentionally not exposed to browser clients yet.

create schema if not exists private;

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 2 and 160),
  legal_name text,
  country_code char(2),
  default_currency char(3),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id)
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  preferred_locale text not null default 'ar',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','admin','commercial_manager','project_manager','quantity_surveyor','reviewer','auditor')),
  status text not null default 'active' check (status in ('invited','active','suspended')),
  created_at timestamptz not null default now(),
  unique (organization_id, user_id),
  unique (organization_id, id)
);
create index organization_members_user_idx on public.organization_members(user_id, organization_id);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  code text,
  name text not null check (length(trim(name)) between 2 and 200),
  description text,
  country_code char(2),
  currency char(3),
  planned_start_date date,
  planned_end_date date,
  status text not null default 'planning' check (status in ('planning','active','on_hold','completed','cancelled')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, id),
  unique (organization_id, code),
  check (planned_end_date is null or planned_start_date is null or planned_end_date >= planned_start_date)
);
create index projects_org_status_idx on public.projects(organization_id, status);

create table public.counterparties (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  name text not null check (length(trim(name)) between 2 and 200),
  party_type text not null check (party_type in ('client','main_contractor','subcontractor','consultant','supplier','other')),
  registration_number text,
  country_code char(2),
  email text,
  phone text,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, id)
);
create index counterparties_org_name_idx on public.counterparties(organization_id, name);

create table public.contracts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  project_id uuid not null,
  counterparty_id uuid,
  contract_number text not null,
  title text not null,
  contract_type text not null default 'other' check (contract_type in ('lump_sum','remeasurement','unit_rate','cost_plus','other')),
  currency char(3) not null,
  original_amount numeric(20,4) not null check (original_amount >= 0),
  signed_date date,
  commencement_date date,
  completion_date date,
  advance_payment_percent numeric(7,4) check (advance_payment_percent between 0 and 100),
  retention_percent numeric(7,4) check (retention_percent between 0 and 100),
  status text not null default 'draft' check (status in ('draft','active','suspended','completed','terminated')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, id),
  unique (organization_id, contract_number),
  foreign key (organization_id, project_id) references public.projects(organization_id, id) on delete restrict,
  foreign key (organization_id, counterparty_id) references public.counterparties(organization_id, id) on delete restrict,
  check (completion_date is null or commencement_date is null or completion_date >= commencement_date)
);
create index contracts_project_idx on public.contracts(organization_id, project_id);

create table public.boq_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  contract_id uuid not null,
  item_code text,
  description text not null,
  section_name text,
  unit text not null,
  contract_quantity numeric(20,4) not null check (contract_quantity >= 0),
  unit_rate numeric(20,4) not null check (unit_rate >= 0),
  currency char(3) not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (organization_id, contract_id) references public.contracts(organization_id, id) on delete restrict,
  unique (organization_id, contract_id, item_code)
);
create index boq_items_contract_idx on public.boq_items(organization_id, contract_id, sort_order);

create or replace function private.is_org_member(target_org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_members m
    where m.organization_id = target_org_id
      and m.user_id = (select auth.uid())
      and m.status = 'active'
  );
$$;

revoke all on function private.is_org_member(uuid) from public;
grant usage on schema private to authenticated;
grant execute on function private.is_org_member(uuid) to authenticated;

alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.organization_members enable row level security;
alter table public.projects enable row level security;
alter table public.counterparties enable row level security;
alter table public.contracts enable row level security;
alter table public.boq_items enable row level security;

create policy "profiles_select_self" on public.profiles
for select to authenticated using (id = (select auth.uid()));
create policy "profiles_insert_self" on public.profiles
for insert to authenticated with check (id = (select auth.uid()));
create policy "profiles_update_self" on public.profiles
for update to authenticated using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy "organizations_select_member" on public.organizations
for select to authenticated using (private.is_org_member(id));

create policy "members_select_same_org" on public.organization_members
for select to authenticated using (private.is_org_member(organization_id));

create policy "projects_member_access" on public.projects
for all to authenticated
using (private.is_org_member(organization_id))
with check (private.is_org_member(organization_id));

create policy "counterparties_member_access" on public.counterparties
for all to authenticated
using (private.is_org_member(organization_id))
with check (private.is_org_member(organization_id));

create policy "contracts_member_access" on public.contracts
for all to authenticated
using (private.is_org_member(organization_id))
with check (
  private.is_org_member(organization_id)
  and exists (
    select 1 from public.projects p
    where p.id = project_id and p.organization_id = contracts.organization_id
  )
);

create policy "boq_items_member_access" on public.boq_items
for all to authenticated
using (private.is_org_member(organization_id))
with check (
  private.is_org_member(organization_id)
  and exists (
    select 1 from public.contracts c
    where c.id = contract_id and c.organization_id = boq_items.organization_id
  )
);

-- Browser access is granted only to authenticated users and remains restricted by RLS.
grant select on public.organizations, public.organization_members to authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.projects, public.counterparties, public.contracts, public.boq_items to authenticated;
