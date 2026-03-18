-- Run this in your Supabase SQL Editor to set up the database schema

create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  display_name text,
  created_at timestamp with time zone default now()
);

create table if not exists public.partnerships (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  partner_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamp with time zone default now(),
  unique(user_id)
);

create table if not exists public.notes (
  id uuid default gen_random_uuid() primary key,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  receiver_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default now()
);

create index if not exists idx_profiles_username on public.profiles(username);
create index if not exists idx_partnerships_user_id on public.partnerships(user_id);
create index if not exists idx_partnerships_partner_id on public.partnerships(partner_id);
create index if not exists idx_notes_receiver_id on public.notes(receiver_id);
create index if not exists idx_notes_sender_id on public.notes(sender_id);
create index if not exists idx_notes_created_at on public.notes(created_at desc);

alter table public.profiles enable row level security;
alter table public.partnerships enable row level security;
alter table public.notes enable row level security;

create policy "Profiles are viewable by authenticated users" on public.profiles
  for select using (auth.role() = 'authenticated');

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "Service role can insert profiles" on public.profiles
  for insert with check (true);

create policy "Partnerships viewable by participants" on public.partnerships
  for select using (auth.uid() = user_id or auth.uid() = partner_id);

create policy "Service role can manage partnerships" on public.partnerships
  for all with check (true);

create policy "Notes viewable by participants" on public.notes
  for select using (auth.uid() = sender_id or auth.uid() = receiver_id);

create policy "Service role can manage notes" on public.notes
  for all with check (true);
