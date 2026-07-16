-- Migration : colonnes manquantes pour le workflow d'acceptation + multi-chiens
-- À exécuter dans Supabase Dashboard → SQL Editor
-- Idempotente : peut être lancée plusieurs fois sans risque.
-- BROUILLON — à valider contre le schéma réel avant exécution.

-- ── demandes : montants et horaires sauvegardés à l'acceptation ──
alter table demandes add column if not exists montant_total   numeric;
alter table demandes add column if not exists montant_acompte numeric;
alter table demandes add column if not exists horaire_arrivee text;    -- 'normal' | 'tard'
alter table demandes add column if not exists horaire_depart  text;    -- 'normal' | 'tot'
alter table demandes add column if not exists jours_fidelite  integer;

-- ── demandes : chiens structurés (multi-chiens propre) ──
alter table demandes add column if not exists chiens_json jsonb;

-- ── demandes : champs chien 1 + suivi (au cas où absents) ──
alter table demandes add column if not exists chien_sexe   text;
alter table demandes add column if not exists chien_age    text;
alter table demandes add column if not exists chien_poids  text;
alter table demandes add column if not exists chien_infos  text;
alter table demandes add column if not exists notes_iolana text;
alter table demandes add column if not exists traitee_le   timestamptz;
alter table demandes add column if not exists option_randonnee boolean default false;
alter table demandes add column if not exists option_album     boolean default false;
alter table demandes add column if not exists option_collier   boolean default false;

-- ── reservations : champs utilisés par confirmerVirement ──
alter table reservations add column if not exists demande_id      uuid;
alter table reservations add column if not exists chien_nom       text;
alter table reservations add column if not exists chiens_json     jsonb;
alter table reservations add column if not exists montant_total   numeric;
alter table reservations add column if not exists montant_acompte numeric;
alter table reservations add column if not exists acompte_recu    boolean default false;
alter table reservations add column if not exists acompte_recu_le date;
alter table reservations add column if not exists option_randonnee boolean default false;
alter table reservations add column if not exists option_album     boolean default false;
alter table reservations add column if not exists option_collier   boolean default false;

-- ── fidelite : au cas où la table n'existe pas encore ──
create table if not exists fidelite (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references clients(id),
  chien_nom text not null,
  jours_cumules integer default 0,
  jours_offerts_total integer default 0,
  jours_offerts_utilises integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
