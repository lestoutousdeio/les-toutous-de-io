-- ═══════════════════════════════════════════════════════════════
-- ANNULATIONS DE RÉSERVATION
-- ═══════════════════════════════════════════════════════════════
-- Le code excluait déjà partout les réservations annulées (planning,
-- disponibilités, chiffre d'affaires) — mais rien ne permettait d'en
-- annuler une. Ces colonnes gardent la trace du « quand » et du « pourquoi ».
--
-- Règle métier : annulation à plus de 30 jours → acompte remboursable ;
-- à moins de 30 jours → acompte conservé, sauf geste commercial.
-- Le remboursement éventuel est enregistré comme un versement négatif
-- dans la table paiements, pour que l'historique reste exact.
--
-- À exécuter dans Supabase Dashboard → SQL Editor. Idempotent.
-- ═══════════════════════════════════════════════════════════════

alter table reservations add column if not exists annule_le        date;
alter table reservations add column if not exists motif_annulation text;
