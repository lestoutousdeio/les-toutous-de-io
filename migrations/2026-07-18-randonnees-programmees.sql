-- ═══════════════════════════════════════════════════════════════
-- RANDONNÉES PROGRAMMÉES
-- ═══════════════════════════════════════════════════════════════
-- Avant : le site devinait tout seul les jeudis d'un séjour pour proposer
--         une randonnée. Faux, car les sorties tombent parfois le vendredi
--         et l'horaire varie.
-- Après : Iolana et Ronan saisissent les dates réelles à l'avance ;
--         le site ne propose que ces sorties-là.
--
-- À exécuter dans Supabase Dashboard → SQL Editor. Idempotent.
-- ═══════════════════════════════════════════════════════════════

create table if not exists randonnees (
  id          uuid primary key default gen_random_uuid(),
  date_sortie date not null,
  heure       text,                 -- ex : « 9h00 » — variable d'une sortie à l'autre
  places_max  integer default 5,
  notes       text,                 -- ex : « Départ La Rhune »
  created_at  timestamptz default now()
);

-- Une seule sortie par jour
create unique index if not exists randonnees_date_unique on randonnees (date_sortie);

alter table randonnees enable row level security;

-- Lecture publique : ce ne sont que des dates de sorties collectives,
-- aucune donnée personnelle. Le site public en a besoin pour les proposer.
drop policy if exists "lecture publique randonnees" on randonnees;
create policy "lecture publique randonnees" on randonnees
  for select to anon, authenticated
  using (true);

-- Seuls Iolana et Ronan peuvent créer / modifier / supprimer
drop policy if exists "admin gere randonnees" on randonnees;
create policy "admin gere randonnees" on randonnees
  for all to authenticated
  using (est_admin()) with check (est_admin());
