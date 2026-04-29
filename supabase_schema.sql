/* ============================================================================
   Blueprint – Project Planner (Supabase / PostgreSQL)
   - Tablas + constraints + seeds
   - updated_at triggers
   - RLS (Row Level Security) + policies
   - Trigger automático de auth.users a public.profiles
   ============================================================================ */

-- 0) Extensiones necesarias
create extension if not exists pgcrypto;

-- 1) Helper: trigger para updated_at
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


-- ============================================================================
-- TABLAS
-- ============================================================================

-- 3) profiles (perfil ligado a auth.users)
drop table if exists public.profiles cascade;
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text unique,
  role text not null check (role in ('manager','developer')),
  avatar_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- TRIGGER AUTOMÁTICO: Insertar perfil al registrarse en Supabase Auth
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, email, role, is_active)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'Nuevo Usuario'),
    new.email,
    'manager', -- manager por defecto para que puedan crear proyectos
    true
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();


-- 4) organizations
drop table if exists public.organizations cascade;
create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

-- 5) organization_members
drop table if exists public.organization_members cascade;
create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  member_role text not null check (member_role in ('owner','admin','member')),
  created_at timestamptz not null default now(),
  unique (organization_id, user_id)
);
create index idx_org_members_org on public.organization_members(organization_id);
create index idx_org_members_user on public.organization_members(user_id);

-- 6) projects
drop table if exists public.projects cascade;
create table public.projects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete set null,
  name text not null,
  description text,
  status text not null default 'active' check (status in ('active','archived')),
  created_by uuid not null references public.profiles(id),
  start_date date,
  end_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_projects_org on public.projects(organization_id);
create index idx_projects_creator on public.projects(created_by);
create trigger trg_projects_updated_at before update on public.projects for each row execute function public.set_updated_at();

-- 7) project_members
drop table if exists public.project_members cascade;
create table public.project_members (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  project_role text not null check (project_role in ('manager','developer')),
  created_at timestamptz not null default now(),
  unique (project_id, user_id)
);
create index idx_project_members_project on public.project_members(project_id);
create index idx_project_members_user on public.project_members(user_id);

-- 8) task_status
drop table if exists public.task_status cascade;
create table public.task_status (
  id smallint primary key,
  code text unique not null check (code in ('pending','in_progress','completed')),
  label text not null,
  sort_order int not null
);
insert into public.task_status(id, code, label, sort_order) values
(1,'pending','Pending',1),
(2,'in_progress','In Progress',2),
(3,'completed','Completed',3)
on conflict (id) do nothing;

-- 9) tasks
drop table if exists public.tasks cascade;
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  description text,
  status_id smallint not null references public.task_status(id),
  priority text not null default 'medium' check (priority in ('low','medium','high')),
  estimated_hours numeric(6,2) not null default 1.00 check (estimated_hours >= 0),
  story_points int check (story_points is null or story_points >= 0),
  due_date date,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_tasks_project on public.tasks(project_id);
create index idx_tasks_status on public.tasks(status_id);
create trigger trg_tasks_updated_at before update on public.tasks for each row execute function public.set_updated_at();

-- 10) task_assignments
drop table if exists public.task_assignments cascade;
create table public.task_assignments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null unique references public.tasks(id) on delete cascade,
  developer_id uuid not null references public.profiles(id) on delete cascade,
  assigned_by uuid not null references public.profiles(id),
  assigned_at timestamptz not null default now()
);
create index idx_task_assign_dev on public.task_assignments(developer_id);

-- 11) task_activity
drop table if exists public.task_activity cascade;
create table public.task_activity (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  actor_id uuid not null references public.profiles(id) on delete cascade,
  action text not null,
  from_value jsonb,
  to_value jsonb,
  created_at timestamptz not null default now()
);
create index idx_task_activity_task on public.task_activity(task_id);

-- 12) chatbot_requests
drop table if exists public.chatbot_requests cascade;
create table public.chatbot_requests (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  requested_by uuid not null references public.profiles(id) on delete cascade,
  prompt text not null,
  result jsonb not null,
  created_tasks uuid[],
  created_at timestamptz not null default now()
);

-- ============================================================================
-- 2) Helper functions (para RLS) - AHORA CREADAS DESPUÉS DE LAS TABLAS
-- ============================================================================
create or replace function public.is_project_member(p_project_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.project_members pm
    where pm.project_id = p_project_id
      and pm.user_id = p_user_id
  );
$$;

create or replace function public.is_project_manager(p_project_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.project_members pm
    where pm.project_id = p_project_id
      and pm.user_id = p_user_id
      and pm.project_role = 'manager'
  );
$$;

create or replace function public.is_task_assignee(p_task_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.task_assignments ta
    where ta.task_id = p_task_id
      and ta.developer_id = p_user_id
  );
$$;

-- ============================================================================
-- RLS (Row Level Security) + POLICIES
-- ============================================================================

alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.projects enable row level security;
alter table public.project_members enable row level security;
alter table public.task_status enable row level security;
alter table public.tasks enable row level security;
alter table public.task_assignments enable row level security;
alter table public.task_activity enable row level security;
alter table public.chatbot_requests enable row level security;

-- PROFILES
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists "profiles_select_project_peers" on public.profiles;
create policy "profiles_select_project_peers" on public.profiles for select to authenticated using (
  exists (
    select 1 from public.project_members pm1
    join public.project_members pm2 on pm1.project_id = pm2.project_id
    where pm1.user_id = auth.uid() and pm2.user_id = public.profiles.id
  )
);

-- ORGS
drop policy if exists "org_select_if_member" on public.organizations;
create policy "org_select_if_member" on public.organizations for select to authenticated using (exists (select 1 from public.organization_members om where om.organization_id = organizations.id and om.user_id = auth.uid()));
drop policy if exists "org_insert_owner" on public.organizations;
create policy "org_insert_owner" on public.organizations for insert to authenticated with check (created_by = auth.uid());

-- ORG MEMBERS
drop policy if exists "org_members_select_if_member" on public.organization_members;
create policy "org_members_select_if_member" on public.organization_members for select to authenticated using (exists (select 1 from public.organization_members om where om.organization_id = organization_members.organization_id and om.user_id = auth.uid()));

-- PROJECTS
drop policy if exists "projects_select_if_member" on public.projects;
create policy "projects_select_if_member" on public.projects for select to authenticated using (public.is_project_member(projects.id, auth.uid()) OR created_by = auth.uid());
drop policy if exists "projects_insert_manager" on public.projects;
create policy "projects_insert_manager" on public.projects for insert to authenticated with check (created_by = auth.uid());
drop policy if exists "projects_update_manager" on public.projects;
create policy "projects_update_manager" on public.projects for update to authenticated using (public.is_project_manager(projects.id, auth.uid())) with check (public.is_project_manager(projects.id, auth.uid()));

-- PROJECT MEMBERS
drop policy if exists "project_members_select_if_member" on public.project_members;
create policy "project_members_select_if_member" on public.project_members for select to authenticated using (public.is_project_member(project_members.project_id, auth.uid()));
drop policy if exists "project_members_manage_manager" on public.project_members;
create policy "project_members_manage_manager" on public.project_members for insert to authenticated with check (
  public.is_project_manager(project_members.project_id, auth.uid()) 
  OR 
  (
    -- Permite auto-añadirse al creador del proyecto en el momento exacto de la creación
    user_id = auth.uid() 
    AND project_role = 'manager'
    AND exists (select 1 from public.projects p where p.id = project_members.project_id and p.created_by = auth.uid())
  )
);
drop policy if exists "project_members_delete_manager" on public.project_members;
create policy "project_members_delete_manager" on public.project_members for delete to authenticated using (
  public.is_project_manager(project_members.project_id, auth.uid())
);

-- TASKS
drop policy if exists "tasks_select_if_project_member" on public.tasks;
create policy "tasks_select_if_project_member" on public.tasks for select to authenticated using (public.is_project_member(tasks.project_id, auth.uid()));
drop policy if exists "tasks_insert_manager" on public.tasks;
create policy "tasks_insert_manager" on public.tasks for insert to authenticated with check (public.is_project_manager(tasks.project_id, auth.uid()) and created_by = auth.uid());
drop policy if exists "tasks_update_manager" on public.tasks;
create policy "tasks_update_manager" on public.tasks for update to authenticated using (public.is_project_manager(tasks.project_id, auth.uid())) with check (public.is_project_manager(tasks.project_id, auth.uid()));
drop policy if exists "tasks_update_assignee_kanban" on public.tasks;
create policy "tasks_update_assignee_kanban" on public.tasks for update to authenticated using (public.is_task_assignee(tasks.id, auth.uid())) with check (public.is_task_assignee(tasks.id, auth.uid()));
drop policy if exists "tasks_delete_manager" on public.tasks;
create policy "tasks_delete_manager" on public.tasks for delete to authenticated using (
  public.is_project_manager(tasks.project_id, auth.uid())
);

-- TASK ASSIGNMENTS (SIN RECURSIÓN INFINITA)
drop policy if exists "assignments_select_if_project_member" on public.task_assignments;
create policy "assignments_select_if_project_member" on public.task_assignments for select to authenticated using (
  exists (select 1 from public.tasks t join public.project_members pm on t.project_id = pm.project_id where t.id = task_assignments.task_id and pm.user_id = auth.uid())
);
drop policy if exists "assignments_insert_manager" on public.task_assignments;
create policy "assignments_insert_manager" on public.task_assignments for insert to authenticated with check (
  exists (select 1 from public.tasks t join public.project_members pm on t.project_id = pm.project_id where t.id = task_assignments.task_id and pm.user_id = auth.uid() and pm.project_role = 'manager') and assigned_by = auth.uid()
);
drop policy if exists "assignments_update_manager" on public.task_assignments;
create policy "assignments_update_manager" on public.task_assignments for update to authenticated using (
  exists (select 1 from public.tasks t join public.project_members pm on t.project_id = pm.project_id where t.id = task_assignments.task_id and pm.user_id = auth.uid() and pm.project_role = 'manager')
) with check (
  exists (select 1 from public.tasks t join public.project_members pm on t.project_id = pm.project_id where t.id = task_assignments.task_id and pm.user_id = auth.uid() and pm.project_role = 'manager') and assigned_by = auth.uid()
);
drop policy if exists "assignments_delete_manager" on public.task_assignments;
create policy "assignments_delete_manager" on public.task_assignments for delete to authenticated using (
  exists (select 1 from public.tasks t join public.project_members pm on t.project_id = pm.project_id where t.id = task_assignments.task_id and pm.user_id = auth.uid() and pm.project_role = 'manager')
);

-- TASK ACTIVITY (SIN RECURSIÓN INFINITA)
drop policy if exists "activity_select_if_project_member" on public.task_activity;
create policy "activity_select_if_project_member" on public.task_activity for select to authenticated using (
  exists (select 1 from public.tasks t join public.project_members pm on t.project_id = pm.project_id where t.id = task_activity.task_id and pm.user_id = auth.uid())
);
drop policy if exists "activity_insert_if_project_member" on public.task_activity;
create policy "activity_insert_if_project_member" on public.task_activity for insert to authenticated with check (
  exists (select 1 from public.tasks t join public.project_members pm on t.project_id = pm.project_id where t.id = task_activity.task_id and pm.user_id = auth.uid()) and actor_id = auth.uid()
);

-- CHATBOT REQUESTS
drop policy if exists "chatbot_select_if_project_member" on public.chatbot_requests;
create policy "chatbot_select_if_project_member" on public.chatbot_requests for select to authenticated using (public.is_project_member(chatbot_requests.project_id, auth.uid()));
drop policy if exists "chatbot_insert_manager" on public.chatbot_requests;
create policy "chatbot_insert_manager" on public.chatbot_requests for insert to authenticated with check (public.is_project_manager(chatbot_requests.project_id, auth.uid()) and requested_by = auth.uid());
