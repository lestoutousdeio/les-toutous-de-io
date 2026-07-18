-- ═══════════════════════════════════════════════════════════════
-- SÉCURISATION DE LA BASE — Row Level Security (RLS)
-- ═══════════════════════════════════════════════════════════════
-- AVANT : la clé publique (visible dans le code des sites) donnait accès
--         en lecture ET écriture à TOUTES les données (clients, emails,
--         téléphones, chiens, réservations).
-- APRÈS : chaque donnée n'est accessible qu'à son propriétaire légitime.
--         · Public (non connecté) : peut déposer une demande + voir les
--           disponibilités agrégées. Rien d'autre.
--         · Client connecté       : uniquement SES données.
--         · Iolana (admin)        : tout.
--
-- À exécuter dans Supabase Dashboard → SQL Editor.
-- Idempotent : peut être relancé sans risque.
-- Rollback disponible en bas du fichier.
-- ═══════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────
-- 1. TABLE DES ADMINISTRATEURS
-- ───────────────────────────────────────────────
create table if not exists admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  email      text,
  created_at timestamptz default now()
);

alter table admins enable row level security;

drop policy if exists "admins lisent la liste" on admins;
create policy "admins lisent la liste" on admins
  for select to authenticated
  using (user_id = auth.uid());


-- ───────────────────────────────────────────────
-- 2. FONCTIONS UTILITAIRES
-- ───────────────────────────────────────────────
-- SECURITY DEFINER : ces fonctions contournent la RLS pour pouvoir
-- répondre à la question « qui es-tu ? » sans boucle infinie.

-- L'utilisateur connecté est-il administrateur ?
create or replace function est_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from admins where user_id = auth.uid());
$$;

-- À quelle fiche client correspond l'utilisateur connecté ? (rattachement par email)
create or replace function mon_client_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from clients
  where lower(email) = lower(auth.jwt() ->> 'email')
  limit 1;
$$;

grant execute on function est_admin()      to anon, authenticated;
grant execute on function mon_client_id()  to anon, authenticated;


-- ───────────────────────────────────────────────
-- 3. OCCUPATION PUBLIQUE (calendrier du site public)
-- ───────────────────────────────────────────────
-- Le site public a besoin de savoir quels jours sont complets, MAIS ne doit
-- jamais voir les données personnelles. Cette fonction ne renvoie que des
-- dates et un nombre de chiens — aucun nom, aucun email, aucun identifiant.
create or replace function occupation_publique()
returns table (date_debut date, date_fin date, nb_chiens int)
language sql
stable
security definer
set search_path = public
as $$
  select r.date_debut, r.date_fin, coalesce(r.nb_chiens, 1)::int
  from reservations r
  where r.service = 'pension'
    and coalesce(r.statut, '') <> 'annule'
    and (r.date_fin is null or r.date_fin >= current_date - interval '1 day');
$$;

grant execute on function occupation_publique() to anon, authenticated;


-- ───────────────────────────────────────────────
-- 4. CLIENTS
-- ───────────────────────────────────────────────
alter table clients enable row level security;

drop policy if exists "client voit sa fiche"   on clients;
drop policy if exists "client modifie sa fiche" on clients;
drop policy if exists "admin gere clients"     on clients;

create policy "client voit sa fiche" on clients
  for select to authenticated
  using (lower(email) = lower(auth.jwt() ->> 'email'));

create policy "client modifie sa fiche" on clients
  for update to authenticated
  using (lower(email) = lower(auth.jwt() ->> 'email'))
  with check (lower(email) = lower(auth.jwt() ->> 'email'));

create policy "admin gere clients" on clients
  for all to authenticated
  using (est_admin()) with check (est_admin());


-- ───────────────────────────────────────────────
-- 5. DEMANDES
-- ───────────────────────────────────────────────
-- Le formulaire public doit pouvoir CRÉER une demande, mais jamais en lire.
alter table demandes enable row level security;

drop policy if exists "public depose une demande" on demandes;
drop policy if exists "client voit ses demandes"  on demandes;
drop policy if exists "admin gere demandes"       on demandes;

create policy "public depose une demande" on demandes
  for insert to anon, authenticated
  with check (true);

create policy "client voit ses demandes" on demandes
  for select to authenticated
  using (client_id is not null and client_id = mon_client_id());

create policy "admin gere demandes" on demandes
  for all to authenticated
  using (est_admin()) with check (est_admin());


-- ───────────────────────────────────────────────
-- 6. RÉSERVATIONS
-- ───────────────────────────────────────────────
alter table reservations enable row level security;

drop policy if exists "client voit ses resas" on reservations;
drop policy if exists "admin gere resas"      on reservations;

create policy "client voit ses resas" on reservations
  for select to authenticated
  using (client_id = mon_client_id());

create policy "admin gere resas" on reservations
  for all to authenticated
  using (est_admin()) with check (est_admin());


-- ───────────────────────────────────────────────
-- 7. FIDÉLITÉ
-- ───────────────────────────────────────────────
alter table fidelite enable row level security;

drop policy if exists "client voit sa fidelite" on fidelite;
drop policy if exists "admin gere fidelite"     on fidelite;

create policy "client voit sa fidelite" on fidelite
  for select to authenticated
  using (client_id = mon_client_id());

create policy "admin gere fidelite" on fidelite
  for all to authenticated
  using (est_admin()) with check (est_admin());


-- ───────────────────────────────────────────────
-- 8. CHIENS (fiches gérées par le client lui-même)
-- ───────────────────────────────────────────────
alter table chiens enable row level security;

drop policy if exists "client gere ses chiens" on chiens;
drop policy if exists "admin gere chiens"      on chiens;

create policy "client gere ses chiens" on chiens
  for all to authenticated
  using (client_id = mon_client_id())
  with check (client_id = mon_client_id());

create policy "admin gere chiens" on chiens
  for all to authenticated
  using (est_admin()) with check (est_admin());


-- ───────────────────────────────────────────────
-- 9. DISPONIBILITÉS (lecture publique : calendrier)
-- ───────────────────────────────────────────────
-- Ne contient que des dates bloquées, aucune donnée personnelle.
alter table disponibilites enable row level security;

drop policy if exists "lecture publique dispos" on disponibilites;
drop policy if exists "admin gere dispos"       on disponibilites;

create policy "lecture publique dispos" on disponibilites
  for select to anon, authenticated
  using (true);

create policy "admin gere dispos" on disponibilites
  for all to authenticated
  using (est_admin()) with check (est_admin());


-- ───────────────────────────────────────────────
-- 10. JOURNAL DES EMAILS (admin uniquement)
-- ───────────────────────────────────────────────
alter table emails_log enable row level security;

drop policy if exists "admin gere emails_log" on emails_log;

create policy "admin gere emails_log" on emails_log
  for all to authenticated
  using (est_admin()) with check (est_admin());


-- ═══════════════════════════════════════════════════════════════
-- APRÈS EXÉCUTION : déclarer Iolana comme administratrice
-- ═══════════════════════════════════════════════════════════════
-- 1. Créer son compte : Dashboard → Authentication → Users → Add user
--    (email + mot de passe, cocher « Auto Confirm User »)
-- 2. Puis exécuter, en remplaçant l'email :
--
--    insert into admins (user_id, email)
--    select id, email from auth.users where email = 'ADRESSE_DE_IOLANA'
--    on conflict (user_id) do nothing;
--
-- 3. Vérifier :  select * from admins;
-- ═══════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════
-- ROLLBACK D'URGENCE (si un site casse) — à exécuter tel quel
-- ═══════════════════════════════════════════════════════════════
-- alter table clients        disable row level security;
-- alter table demandes       disable row level security;
-- alter table reservations   disable row level security;
-- alter table fidelite       disable row level security;
-- alter table chiens         disable row level security;
-- alter table disponibilites disable row level security;
-- alter table emails_log     disable row level security;
-- ═══════════════════════════════════════════════════════════════
