-- Comprehensive metrics extension for FitComp
-- Adds strength/body/recovery/nutrition persistence primitives.

create table if not exists public.personal_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exercise_name text not null,
  record_type text not null check (record_type in ('max_weight', 'max_reps', 'max_volume')),
  value numeric not null check (value >= 0),
  achieved_at timestamptz not null default now(),
  session_id uuid null,
  created_at timestamptz not null default now()
);

create index if not exists idx_personal_records_user_exercise
  on public.personal_records (user_id, exercise_name, achieved_at desc);

create table if not exists public.body_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  recorded_on date not null default current_date,
  body_fat_pct numeric null check (body_fat_pct >= 0 and body_fat_pct <= 80),
  waist_cm numeric null check (waist_cm >= 0),
  source text not null default 'manual',
  created_at timestamptz not null default now(),
  unique (user_id, recorded_on)
);

create index if not exists idx_body_metrics_user_date
  on public.body_metrics (user_id, recorded_on desc);

create table if not exists public.nutrition_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_at timestamptz not null default now(),
  calories integer not null default 0,
  protein_g integer not null default 0,
  carbs_g integer not null default 0,
  fat_g integer not null default 0,
  fiber_g integer not null default 0,
  sodium_mg integer not null default 0,
  water_ml integer not null default 0,
  notes text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_nutrition_log_user_logged_at
  on public.nutrition_log (user_id, logged_at desc);

create table if not exists public.recovery_daily (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  recorded_on date not null default current_date,
  sleep_hours numeric not null default 0,
  resting_hr numeric null,
  hrv_sdnn numeric null,
  vo2_max numeric null,
  readiness_score integer not null default 0,
  stress_score integer not null default 0,
  recovery_score integer not null default 0,
  overtraining_flag boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, recorded_on)
);

alter table public.personal_records enable row level security;
alter table public.body_metrics enable row level security;
alter table public.nutrition_log enable row level security;
alter table public.recovery_daily enable row level security;

create policy if not exists "users_manage_own_personal_records"
  on public.personal_records
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy if not exists "users_manage_own_body_metrics"
  on public.body_metrics
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy if not exists "users_manage_own_nutrition_log"
  on public.nutrition_log
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy if not exists "users_manage_own_recovery_daily"
  on public.recovery_daily
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
