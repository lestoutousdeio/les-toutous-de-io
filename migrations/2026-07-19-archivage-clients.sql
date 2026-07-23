-- ═══════════════════════════════════════════════════════════════
-- ARCHIVAGE DES CLIENTS
-- ═══════════════════════════════════════════════════════════════
-- Alternative douce à la suppression : un client qui ne vient plus est
-- « rangé » (retiré des listes courantes) sans perdre son historique
-- (réservations, paiements, fidélité). Réversible à tout moment.
--
-- On stocke la date d'archivage plutôt qu'un simple booléen : ça garde
-- la trace du « quand ». archive_le IS NULL = client actif.
--
-- À exécuter dans Supabase Dashboard → SQL Editor. Idempotent.
-- ═══════════════════════════════════════════════════════════════

alter table clients add column if not exists archive_le date;
