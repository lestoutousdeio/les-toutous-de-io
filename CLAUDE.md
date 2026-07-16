# Les Toutous de Io — Pension canine familiale

Site pour une pension canine à Saint-Pée-sur-Nivelle (Pays Basque), tenue par Iolana.

## Architecture

- `public/index.html` — site public standalone (formulaire de demande) → https://lestoutousdeio.netlify.app
- `admin/index.html` — interface admin standalone → https://lestoutousdeioadmin.netlify.app
- HTML/CSS/JS vanilla, aucun framework, aucun build. Chaque fichier est autonome.
- Déploiement : GitHub → Netlify automatique. Chaque site Netlify pointe sur son dossier
  (base directory `public` ou `admin`, pas de commande de build). Un push sur `main` déploie les deux.
- Base de données : Supabase (PostgreSQL), accès via clé publishable côté client.
- Hébergement : Netlify (deux sites distincts, un par fichier).
- Emails : EmailJS (service `service_r8y448c`, templates `confirmation_demande`, `garde_acceptee`) — **pas encore fonctionnel**.
- Auth admin : mot de passe JS côté client uniquement (pas de vraie auth pour l'instant).

## Supabase

- URL : `https://xtxekhowasjzzplkskvf.supabase.co`
- Clé publishable : `sb_publishable_siYC9zq1W1LRfwgjtJ2vCg_be1Eo0-c`

Tables : `clients` (statuts nouveau/rencontre/test/valide/refuse), `chiens` (plusieurs par client),
`demandes` (statuts en_attente/rencontre/test/acceptee/virement_ok/refusee/annulee),
`reservations` (créées après confirmation virement), `disponibilites` (dates bloquées),
`fidelite` (1 jour offert / 12 jours de pension, par chien), `emails_log`.

## Règles métier

- Pension : 25 €/jour (1 chien), 20 €/chien/jour (2+ chiens du même foyer). Max 4 chiens simultanés.
- Randonnée montagne : jeudis matin uniquement, max 5 chiens. 30 €/chien, 25 € si 2 chiens même foyer, 20 € si en pension.
- Visite domicile (30 min) et balade (1 h) : tarif selon zone 1/2/3. Transport : rayon 60 km.
- Album photo 30 €, collier personnalisé 15 €.
- Arrivée après 18 h ou départ avant 11 h = demi-journée à 15 €, non comptée pour la fidélité.
- Mâles non castrés refusés.
- Acompte 20 % à la réservation, remboursable si annulation > 30 jours avant.
- Parcours nouveau client : demande → rencontre → demi-journée test → validation → compte client.

## Reste à faire

1. Espace client (Supabase Auth, dashboard, réservation pré-remplie, historique, carte fidélité)
2. Emails automatiques (déboguer EmailJS ou migrer vers Resend)
3. Déploiement auto Netlify via GitHub
4. Domaine `lestoutousdeio.fr`

## Précautions

- Supabase plan gratuit : le projet se met en pause après ~1 semaine sans activité →
  le site ne fonctionne plus tant qu'il n'est pas restauré depuis le dashboard.
- Dépôt GitHub privé : le mot de passe admin est en clair dans `admin/index.html`.
- `captures-bugs/` contient des captures d'écran de bugs signalés (non versionnées).
- `migrations/` : SQL à exécuter manuellement dans Supabase Dashboard → SQL Editor.
