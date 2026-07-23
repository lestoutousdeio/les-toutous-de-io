-- ═══════════════════════════════════════════════════════════════
-- FIDÉLITÉ : DÉDUCTION AUTOMATIQUE ET RESTITUTION À L'ANNULATION
-- ═══════════════════════════════════════════════════════════════
-- 1. Le jour offert se déduit désormais tout seul du montant à
--    l'acceptation d'une pension.
-- 2. Si le séjour est annulé, on rembobine la fidélité : les jours
--    crédités sont retirés et les jours offerts consommés sont rendus.
--    (Avant, un client pouvait réserver 12 jours, encaisser son jour
--    offert, puis annuler en le conservant.)
--
-- fidelite_json mémorise, par chien, ce que la réservation a fait à la
-- carte : [{ "chien": "Rex", "gagnes": 12, "offerts": 1 }, ...]. C'est
-- ce détail qui permet une annulation exacte.
--
-- À exécuter dans Supabase Dashboard → SQL Editor. Idempotent.
-- ═══════════════════════════════════════════════════════════════

alter table demandes     add column if not exists fidelite_json jsonb;
alter table reservations add column if not exists fidelite_json jsonb;
