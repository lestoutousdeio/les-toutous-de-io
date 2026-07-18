-- ═══════════════════════════════════════════════════════════════
-- DATE DE NAISSANCE DES CHIENS
-- ═══════════════════════════════════════════════════════════════
-- Avant : l'âge était saisi en texte libre (« 3 ans ») et devenait faux
--         l'année suivante — personne ne pense à le mettre à jour.
-- Après : on stocke la date de naissance, l'âge est recalculé à l'affichage.
--
-- L'ancienne colonne « age » est conservée pour les fiches déjà saisies.
-- À exécuter dans Supabase Dashboard → SQL Editor. Idempotent.
-- ═══════════════════════════════════════════════════════════════

alter table chiens add column if not exists date_naissance date;
