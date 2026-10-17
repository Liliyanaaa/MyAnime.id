-- Jalankan di Supabase > SQL Editor
create table profiles(id uuid primary key references auth.users on delete cascade,email text,is_premium boolean default false,is_admin boolean default false,premium_until timestamptz);
create table watch_log(id bigserial primary key,user_id uuid references auth.users,mal_id int,ep int,day date default (now() at time zone 'Asia/Jakarta')::date);
create table payment_requests(id bigserial primary key,user_id uuid,email text,months int,amount int,status text default 'pending',created_at timestamptz default now());
create table reports(id bigserial primary key,mal_id int,ep int,note text,created_at timestamptz default now());
create table video_sources(id bigserial primary key,mal_id int,ep int,server int,quality text,url text,sub_url text);
alter table profiles enable row level security;alter table watch_log enable row level security;alter table payment_requests enable row level security;alter table reports enable row level security;alter table video_sources enable row level security;
create function is_admin() returns boolean language sql security definer as $$select coalesce((select is_admin from profiles where id=auth.uid()),false)$$;
create function is_prem() returns boolean language sql security definer as $$select coalesce((select is_premium and (premium_until is null or premium_until>now()) from profiles where id=auth.uid()),false)$$;
create policy p1 on profiles for select using(id=auth.uid() or is_admin());
create policy p2 on profiles for update using(is_admin());
create policy w1 on watch_log for select using(user_id=auth.uid());
create policy w2 on watch_log for insert with check(user_id=auth.uid() and (is_prem() or (select count(*) from watch_log w where w.user_id=auth.uid() and w.day=watch_log.day)<5));
create policy r1 on payment_requests for insert with check(user_id=auth.uid());
create policy r2 on payment_requests for select using(user_id=auth.uid() or is_admin());
create policy r3 on payment_requests for update using(is_admin());
create policy t1 on reports for insert with check(true);
create policy t2 on reports for select using(is_admin());
create policy v1 on video_sources for select using(true);
create policy v2 on video_sources for all using(is_admin());
create function new_user() returns trigger language plpgsql security definer as $$begin insert into profiles(id,email) values(new.id,new.email);return new;end$$;
create trigger on_signup after insert on auth.users for each row execute function new_user();
-- Jadikan akun admin setelah akun itu terdaftar lewat halaman Daftar:
update profiles set is_admin=true where email='websitescarlett@gmail.com';
