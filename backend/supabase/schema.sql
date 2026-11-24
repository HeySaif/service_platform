-- Service Platform — Supabase schema (run in Supabase SQL Editor)
-- Matches docs/03_DOMAIN_AND_DATA_MODEL.md

-- ============ TABLES ============
create table public.app_users (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  phone text not null default '',
  city text not null default 'Lahore',
  avatar_url text,
  active_role text not null default 'CLIENT' check (active_role in ('CLIENT','PROVIDER')),
  is_provider_onboarded boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.provider_profiles (
  user_id uuid primary key references public.app_users(id) on delete cascade,
  display_name text not null,
  bio text not null,
  categories text[] not null default '{}',
  city text not null,
  service_areas text[] not null default '{}',
  is_available boolean not null default true,
  rating_average numeric(3,2) not null default 0,
  review_count int not null default 0,
  completed_bookings_count int not null default 0,
  updated_at timestamptz not null default now()
);

create table public.service_requests (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.app_users(id) on delete cascade,
  client_name text not null,
  title text not null check (char_length(title) between 5 and 80),
  category text not null check (category in
    ('ELECTRICAL','PLUMBING','AC_REPAIR','CLEANING','CARPENTRY','PAINTING','HANDYMAN')),
  description text not null check (char_length(description) between 10 and 1000),
  city text not null,
  area_name text not null,
  budget_pkr numeric check (budget_pkr is null or budget_pkr > 0),
  photo_urls text[] not null default '{}' check (cardinality(photo_urls) <= 3),
  status text not null default 'OPEN' check (status in ('OPEN','BOOKED','COMPLETED','CANCELLED')),
  bid_count int not null default 0,
  created_at timestamptz not null default now()
);

-- address_details is split out so it can stay hidden until a booking exists
create table public.request_addresses (
  request_id uuid primary key references public.service_requests(id) on delete cascade,
  address_details text not null
);

create table public.bids (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.service_requests(id) on delete cascade,
  provider_id uuid not null references public.provider_profiles(user_id) on delete cascade,
  provider_name text not null,
  provider_rating numeric(3,2) not null default 0,
  proposed_price numeric not null check (proposed_price > 0),
  message text not null,
  status text not null default 'PENDING' check (status in ('PENDING','ACCEPTED','REJECTED','WITHDRAWN')),
  created_at timestamptz not null default now()
);
-- One active bid per (request, provider)
create unique index one_active_bid on public.bids(request_id, provider_id)
  where status in ('PENDING','ACCEPTED');

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.service_requests(id) on delete cascade,
  bid_id uuid not null references public.bids(id),
  client_id uuid not null references public.app_users(id),
  provider_id uuid not null references public.provider_profiles(user_id),
  agreed_price numeric not null,
  status text not null default 'CONFIRMED' check (status in ('CONFIRMED','WORK_DONE','COMPLETED','CANCELLED')),
  cancelled_by text check (cancelled_by in ('CLIENT','PROVIDER')),
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_id uuid not null references public.app_users(id),
  sender_name text not null,
  text text not null check (char_length(text) > 0),
  created_at timestamptz not null default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  request_id uuid not null references public.service_requests(id),
  client_id uuid not null references public.app_users(id),
  client_name text not null,
  provider_id uuid not null references public.provider_profiles(user_id),
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

-- ============ TRIGGERS ============
-- Create app_users row on signup (metadata: full_name, phone, city)
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.app_users (id, full_name, email, phone, city)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
          new.email,
          coalesce(new.raw_user_meta_data->>'phone',''),
          coalesce(new.raw_user_meta_data->>'city','Lahore'));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep service_requests.bid_count in sync with PENDING bids
create or replace function public.sync_bid_count() returns trigger
language plpgsql security definer set search_path = public as $$
declare rid uuid := coalesce(new.request_id, old.request_id);
begin
  update public.service_requests
     set bid_count = (select count(*) from public.bids where request_id = rid and status = 'PENDING')
   where id = rid;
  return null;
end $$;
create trigger bids_count_sync after insert or update or delete on public.bids
  for each row execute function public.sync_bid_count();

-- Enforce bid rules: request must be OPEN, no bidding on own request, snapshot provider info
create or replace function public.before_bid_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare r public.service_requests; p public.provider_profiles;
begin
  select * into r from public.service_requests where id = new.request_id;
  if r.status <> 'OPEN' then raise exception 'Request is not open for bids'; end if;
  if r.client_id = new.provider_id then raise exception 'You cannot bid on your own request'; end if;
  select * into p from public.provider_profiles where user_id = new.provider_id;
  new.provider_name := p.display_name;
  new.provider_rating := p.rating_average;
  new.status := 'PENDING';
  return new;
end $$;
create trigger bid_before_insert before insert on public.bids
  for each row execute function public.before_bid_insert();

-- ============ RPC (atomic state transitions) ============
create or replace function public.accept_bid(p_bid_id uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare b public.bids; r public.service_requests; new_booking uuid;
begin
  select * into b from public.bids where id = p_bid_id for update;
  if not found or b.status <> 'PENDING' then raise exception 'Bid is not pending'; end if;
  select * into r from public.service_requests where id = b.request_id for update;
  if r.client_id <> auth.uid() then raise exception 'Not your request'; end if;
  if r.status <> 'OPEN' then raise exception 'Request is not open'; end if;

  update public.bids set status = 'ACCEPTED' where id = b.id;
  update public.bids set status = 'REJECTED'
   where request_id = r.id and id <> b.id and status = 'PENDING';
  update public.service_requests set status = 'BOOKED' where id = r.id;
  insert into public.bookings (request_id, bid_id, client_id, provider_id, agreed_price)
  values (r.id, b.id, r.client_id, b.provider_id, b.proposed_price)
  returning id into new_booking;
  return new_booking;
end $$;

create or replace function public.mark_work_done(p_booking_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.bookings set status = 'WORK_DONE'
   where id = p_booking_id and provider_id = auth.uid() and status = 'CONFIRMED';
  if not found then raise exception 'Cannot mark work done'; end if;
end $$;

create or replace function public.complete_booking(p_booking_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare b public.bookings;
begin
  update public.bookings set status = 'COMPLETED', completed_at = now()
   where id = p_booking_id and client_id = auth.uid() and status = 'WORK_DONE'
   returning * into b;
  if not found then raise exception 'Cannot complete booking'; end if;
  update public.service_requests set status = 'COMPLETED' where id = b.request_id;
  update public.provider_profiles
     set completed_bookings_count = completed_bookings_count + 1, updated_at = now()
   where user_id = b.provider_id;
end $$;

create or replace function public.cancel_booking(p_booking_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare b public.bookings; who text;
begin
  select * into b from public.bookings where id = p_booking_id for update;
  if not found or b.status not in ('CONFIRMED','WORK_DONE') then
    raise exception 'Booking cannot be cancelled';
  end if;
  if auth.uid() = b.client_id then who := 'CLIENT';
  elsif auth.uid() = b.provider_id then who := 'PROVIDER';
  else raise exception 'Not allowed'; end if;
  update public.bookings set status = 'CANCELLED', cancelled_by = who where id = b.id;
  update public.service_requests set status = 'CANCELLED' where id = b.request_id;
end $$;

create or replace function public.submit_review(p_booking_id uuid, p_rating int, p_comment text)
returns void language plpgsql security definer set search_path = public as $$
declare b public.bookings; cname text;
begin
  select * into b from public.bookings where id = p_booking_id;
  if not found or b.client_id <> auth.uid() or b.status <> 'COMPLETED' then
    raise exception 'Cannot review this booking';
  end if;
  select full_name into cname from public.app_users where id = auth.uid();
  insert into public.reviews (booking_id, request_id, client_id, client_name, provider_id, rating, comment)
  values (b.id, b.request_id, b.client_id, cname, b.provider_id, p_rating, nullif(trim(p_comment),''));
  update public.provider_profiles p
     set review_count = s.cnt, rating_average = round(s.avg_r::numeric, 2), updated_at = now()
    from (select count(*) cnt, avg(rating) avg_r from public.reviews where provider_id = b.provider_id) s
   where p.user_id = b.provider_id;
end $$;

-- ============ ROW LEVEL SECURITY ============
alter table public.app_users enable row level security;
alter table public.provider_profiles enable row level security;
alter table public.service_requests enable row level security;
alter table public.request_addresses enable row level security;
alter table public.bids enable row level security;
alter table public.bookings enable row level security;
alter table public.chat_messages enable row level security;
alter table public.reviews enable row level security;

-- app_users: any signed-in user may read (names on bids/chat); only self may edit
create policy users_read on public.app_users for select to authenticated using (true);
create policy users_update on public.app_users for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- provider_profiles: public read, owner write
create policy pp_read on public.provider_profiles for select to authenticated using (true);
create policy pp_insert on public.provider_profiles for insert to authenticated with check (user_id = auth.uid());
create policy pp_update on public.provider_profiles for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- service_requests: OPEN ones visible to all, otherwise only parties involved
create policy sr_read on public.service_requests for select to authenticated using (
  status = 'OPEN' or client_id = auth.uid()
  or exists (select 1 from public.bookings b where b.request_id = id and b.provider_id = auth.uid())
);
create policy sr_insert on public.service_requests for insert to authenticated
  with check (client_id = auth.uid() and status = 'OPEN');
-- clients may only cancel their own OPEN request directly; other transitions go through RPCs
create policy sr_cancel on public.service_requests for update to authenticated
  using (client_id = auth.uid() and status = 'OPEN')
  with check (client_id = auth.uid() and status in ('OPEN','CANCELLED'));

-- addresses: owner always; provider only once booked
create policy ra_owner on public.request_addresses for all to authenticated
  using (exists (select 1 from public.service_requests r where r.id = request_id and r.client_id = auth.uid()))
  with check (exists (select 1 from public.service_requests r where r.id = request_id and r.client_id = auth.uid()));
create policy ra_booked_provider on public.request_addresses for select to authenticated
  using (exists (select 1 from public.bookings b
                 where b.request_id = request_addresses.request_id and b.provider_id = auth.uid()));

-- bids: provider sees own, client sees bids on their request
create policy bids_read on public.bids for select to authenticated using (
  provider_id = auth.uid()
  or exists (select 1 from public.service_requests r where r.id = request_id and r.client_id = auth.uid())
);
create policy bids_insert on public.bids for insert to authenticated with check (provider_id = auth.uid());
-- provider may update price/message or withdraw while PENDING
create policy bids_update on public.bids for update to authenticated
  using (provider_id = auth.uid() and status = 'PENDING')
  with check (provider_id = auth.uid() and status in ('PENDING','WITHDRAWN'));

-- bookings: parties only (writes via RPC)
create policy bookings_read on public.bookings for select to authenticated
  using (client_id = auth.uid() or provider_id = auth.uid());

-- chat: booking parties only
create policy chat_read on public.chat_messages for select to authenticated using (
  exists (select 1 from public.bookings b where b.id = booking_id
          and (b.client_id = auth.uid() or b.provider_id = auth.uid())));
create policy chat_insert on public.chat_messages for insert to authenticated with check (
  sender_id = auth.uid() and exists (select 1 from public.bookings b where b.id = booking_id
          and b.status in ('CONFIRMED','WORK_DONE')
          and (b.client_id = auth.uid() or b.provider_id = auth.uid())));

-- reviews: public read (writes via submit_review RPC)
create policy reviews_read on public.reviews for select to authenticated using (true);

-- ============ REALTIME & STORAGE ============
alter publication supabase_realtime add table public.chat_messages, public.bids, public.bookings, public.service_requests;

insert into storage.buckets (id, name, public) values ('request-photos','request-photos', true)
  on conflict (id) do nothing;
create policy photos_upload on storage.objects for insert to authenticated
  with check (bucket_id = 'request-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy photos_read on storage.objects for select using (bucket_id = 'request-photos');

-- ============ API PERMISSIONS ============
-- Needed if "Grant API access to new tables automatically" was NOT ticked when the project was created.
-- RLS policies above still decide which rows each user can see.
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on all functions in schema public to authenticated;
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public grant execute on functions to authenticated;
