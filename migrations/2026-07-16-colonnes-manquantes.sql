-- Migration : chiens structurés + horaires/fidélité sur les demandes
-- Vérifiée contre le schéma réel le 16/07/2026.
-- À exécuter dans Supabase Dashboard → SQL Editor.
-- Idempotente : peut être lancée plusieurs fois sans risque.

-- Fiches complètes de tous les chiens de la demande (multi-chiens propre)
alter table demandes add column if not exists chiens_json jsonb;

-- Choix d'horaires faits à l'acceptation (survivent au rechargement de la page)
alter table demandes add column if not exists arrivee_tardive boolean default false;
alter table demandes add column if not exists depart_tot      boolean default false;
alter table demandes add column if not exists jours_fidelite  integer;

-- Copie des fiches chiens sur la réservation confirmée
alter table reservations add column if not exists chiens_json jsonb;
