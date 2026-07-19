-- ═══════════════════════════════════════════════════════════════
-- SUIVI DES PAIEMENTS
-- ═══════════════════════════════════════════════════════════════
-- Avant : on savait seulement « acompte reçu oui/non ». Impossible de
--         connaître le solde restant dû, ni d'enregistrer un versement
--         partiel ou un paiement en deux fois.
-- Après : chaque versement est une ligne. Le solde se calcule :
--         reste = montant_total − somme des paiements.
--
-- À exécuter dans Supabase Dashboard → SQL Editor. Idempotent.
-- ═══════════════════════════════════════════════════════════════

create table if not exists paiements (
  id             uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references reservations(id) on delete cascade,
  client_id      uuid references clients(id) on delete set null,
  montant        numeric(10,2) not null,
  date_paiement  date not null default current_date,
  moyen          text,          -- virement | especes | cheque | autre
  note           text,
  created_at     timestamptz default now()
);

create index if not exists paiements_reservation_idx on paiements (reservation_id);
create index if not exists paiements_client_idx      on paiements (client_id);

alter table paiements enable row level security;

-- Le client consulte ses propres versements (transparence), sans pouvoir
-- en créer : seuls Iolana et Ronan enregistrent les encaissements.
drop policy if exists "client voit ses paiements" on paiements;
create policy "client voit ses paiements" on paiements
  for select to authenticated
  using (client_id = mon_client_id());

drop policy if exists "admin gere paiements" on paiements;
create policy "admin gere paiements" on paiements
  for all to authenticated
  using (est_admin()) with check (est_admin());


-- ───────────────────────────────────────────────
-- REPRISE DES ACOMPTES DÉJÀ ENCAISSÉS
-- ───────────────────────────────────────────────
-- Les réservations confirmées avant cette migration portent un acompte
-- sous forme de simple drapeau. On le transforme en vrai paiement pour
-- que les soldes soient justes dès le premier affichage.
insert into paiements (reservation_id, client_id, montant, date_paiement, moyen, note)
select r.id,
       r.client_id,
       r.montant_acompte,
       coalesce(r.acompte_recu_le, current_date),
       'virement',
       'Acompte (repris automatiquement)'
from reservations r
where r.acompte_recu = true
  and coalesce(r.montant_acompte, 0) > 0
  and not exists (select 1 from paiements p where p.reservation_id = r.id);


-- ═══════════════════════════════════════════════════════════════
-- Vérification :
--   select r.chien_nom, r.montant_total,
--          coalesce(sum(p.montant), 0) as paye,
--          r.montant_total - coalesce(sum(p.montant), 0) as reste
--   from reservations r
--   left join paiements p on p.reservation_id = r.id
--   group by r.id, r.chien_nom, r.montant_total;
-- ═══════════════════════════════════════════════════════════════
