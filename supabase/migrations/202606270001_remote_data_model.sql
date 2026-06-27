create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  reader_name text,
  greeting text,
  custom_greeting text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  local_book_id text not null,
  title text not null,
  author text,
  isbn text,
  cover_url text,
  total_pages integer,
  current_page integer,
  status text not null,
  rating numeric(3, 2),
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint books_total_pages_non_negative check (
    total_pages is null or total_pages >= 0
  ),
  constraint books_current_page_non_negative check (
    current_page is null or current_page >= 0
  ),
  constraint books_rating_range check (
    rating is null or (rating >= 0 and rating <= 5)
  ),
  constraint books_status_valid check (
    status in ('pending', 'reading', 'completed', 'paused', 'abandoned')
  )
);

create table if not exists public.reading_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  local_session_id text not null,
  local_book_id text not null,
  remote_book_id uuid references public.books(id) on delete set null,
  pages_read integer not null default 0,
  minutes_read integer not null default 0,
  note text,
  session_date date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint reading_sessions_pages_read_non_negative check (pages_read >= 0),
  constraint reading_sessions_minutes_read_non_negative check (minutes_read >= 0)
);

create table if not exists public.annual_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  local_goal_id text,
  year integer not null,
  target_books integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint annual_goals_year_valid check (year >= 2000 and year <= 2100),
  constraint annual_goals_target_books_positive check (target_books > 0)
);

create unique index if not exists profiles_active_id_idx
  on public.profiles (id)
  where deleted_at is null;

create unique index if not exists books_user_local_book_id_idx
  on public.books (user_id, local_book_id)
  where deleted_at is null;

create index if not exists books_user_updated_at_idx
  on public.books (user_id, updated_at);

create unique index if not exists reading_sessions_user_local_session_id_idx
  on public.reading_sessions (user_id, local_session_id)
  where deleted_at is null;

create index if not exists reading_sessions_user_updated_at_idx
  on public.reading_sessions (user_id, updated_at);

create unique index if not exists annual_goals_user_year_idx
  on public.annual_goals (user_id, year)
  where deleted_at is null;

create index if not exists annual_goals_user_updated_at_idx
  on public.annual_goals (user_id, updated_at);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

drop trigger if exists books_set_updated_at on public.books;
create trigger books_set_updated_at
  before update on public.books
  for each row
  execute function public.set_updated_at();

drop trigger if exists reading_sessions_set_updated_at
  on public.reading_sessions;
create trigger reading_sessions_set_updated_at
  before update on public.reading_sessions
  for each row
  execute function public.set_updated_at();

drop trigger if exists annual_goals_set_updated_at on public.annual_goals;
create trigger annual_goals_set_updated_at
  before update on public.annual_goals
  for each row
  execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.books enable row level security;
alter table public.reading_sessions enable row level security;
alter table public.annual_goals enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_delete_own" on public.profiles;

create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "profiles_delete_own"
  on public.profiles for delete
  using (auth.uid() = id);

drop policy if exists "books_select_own" on public.books;
drop policy if exists "books_insert_own" on public.books;
drop policy if exists "books_update_own" on public.books;
drop policy if exists "books_delete_own" on public.books;

create policy "books_select_own"
  on public.books for select
  using (auth.uid() = user_id);

create policy "books_insert_own"
  on public.books for insert
  with check (auth.uid() = user_id);

create policy "books_update_own"
  on public.books for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "books_delete_own"
  on public.books for delete
  using (auth.uid() = user_id);

drop policy if exists "reading_sessions_select_own" on public.reading_sessions;
drop policy if exists "reading_sessions_insert_own" on public.reading_sessions;
drop policy if exists "reading_sessions_update_own" on public.reading_sessions;
drop policy if exists "reading_sessions_delete_own" on public.reading_sessions;

create policy "reading_sessions_select_own"
  on public.reading_sessions for select
  using (auth.uid() = user_id);

create policy "reading_sessions_insert_own"
  on public.reading_sessions for insert
  with check (auth.uid() = user_id);

create policy "reading_sessions_update_own"
  on public.reading_sessions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "reading_sessions_delete_own"
  on public.reading_sessions for delete
  using (auth.uid() = user_id);

drop policy if exists "annual_goals_select_own" on public.annual_goals;
drop policy if exists "annual_goals_insert_own" on public.annual_goals;
drop policy if exists "annual_goals_update_own" on public.annual_goals;
drop policy if exists "annual_goals_delete_own" on public.annual_goals;

create policy "annual_goals_select_own"
  on public.annual_goals for select
  using (auth.uid() = user_id);

create policy "annual_goals_insert_own"
  on public.annual_goals for insert
  with check (auth.uid() = user_id);

create policy "annual_goals_update_own"
  on public.annual_goals for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "annual_goals_delete_own"
  on public.annual_goals for delete
  using (auth.uid() = user_id);
