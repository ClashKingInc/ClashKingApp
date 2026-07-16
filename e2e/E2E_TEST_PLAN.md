# ClashKing — E2E Test Plan

> Tests Playwright contre `https://app.clashk.ing` (ou URL configurée via `BASE_URL`).
> Moteur : Chromium headless, Flutter web (semantics tree activé).

---

## Légende

| Icône | Signification |
|---|---|
| ✅ | Implémenté |
| 🔲 | À faire |
| ⚠️ | Partiel / conditionnel |
| 🔑 | Nécessite `TEST_EMAIL` / `TEST_PASSWORD` |
| 🎮 | Nécessite un compte CoC lié (voir §Prérequis) |
| 📧 | Nécessite accès à la boîte mail (difficile en CI) |

---

## Prérequis secrets GitHub

| Secret | Usage |
|---|---|
| `E2E_TEST_EMAIL` | Compte de test email/password |
| `E2E_TEST_PASSWORD` | Mot de passe du compte |
| `E2E_TEST_COC_TAG` | Tag joueur CoC pré-lié au compte (ex: `#2PP`) |
| `E2E_TEST_COC_TOKEN` | Token API du joueur pour vérification |

> **Note CoC** : Les tests §8–§15 nécessitent un compte de test avec un joueur CoC
> déjà lié dans MongoDB. Le plus simple est de créer un compte dédié via l'app,
> d'y lier un compte CoC manuellement, puis d'utiliser ses tokens comme secrets CI.

---

## §1 — Smoke / App loading

**Fichier** : `smoke.spec.ts` | **Projet** : `chromium`

| # | Test | Status |
|---|---|---|
| 1.1 | Page retourne HTTP 200 | ✅ |
| 1.2 | `flt-glass-pane` monté (Flutter initialisé) | ✅ |
| 1.3 | Titre de la page contient "ClashKing" | ✅ |
| 1.4 | Aucune erreur JavaScript à l'ouverture | ✅ |
| 1.5 | Chargement initial < 20 s | ✅ |
| 1.6 | Pas de requête réseau en erreur 5xx au démarrage | ✅ |

---

## §2 — Authentification — Page de login

**Fichiers** : `auth.spec.ts`, `login.spec.ts` | **Projet** : `chromium`

| # | Test | Status |
|---|---|---|
| 2.1 | Page de login visible (flt-semantics présents) | ✅ |
| 2.2 | Onglets Discord et Email visibles | ✅ |
| 2.3 | Onglet Discord sélectionné par défaut | ✅ |
| 2.4 | Bouton Discord "Continue with Discord" visible | ✅ |
| 2.5 | Email tab : champ Email + champ Password + bouton Login | ✅ |
| 2.6 | Liens "Forgot password?" et "Sign up" visibles | ✅ |
| 2.7 | Formulaire vide → validation bloque la soumission | ✅ |
| 2.8 | Login complet avec `TEST_EMAIL`/`TEST_PASSWORD` 🔑 | ✅ |
| 2.9 | Mauvais mot de passe → message d'erreur ou reste sur login 🔑 | ✅ |
| 2.10 | Email malformé → validation bloque avant envoi | ✅ |
| 2.11 | Compte non vérifié → redirige vers page de vérification | 🔲 |

---

## §3 — Authentification — Inscription (Register)

**Fichier** : `register.spec.ts` | **Projet** : `chromium`

| # | Test | Status |
|---|---|---|
| 3.1 | Page d'inscription accessible via "Sign up" | ✅ |
| 3.2 | Champs Username, Email, Password, Confirm Password présents | ✅ |
| 3.3 | Bouton "Create Account" visible | ✅ |
| 3.4 | Formulaire vide → validation bloque | ✅ |
| 3.5 | Username < 3 caractères → validation bloque | ✅ |
| 3.6 | Passwords différents → validation bloque | ✅ |
| 3.7 | "Already have an account?" → retour login | ✅ |
| 3.8 | Password sans majuscule → validation bloque | ✅ |
| 3.9 | Password sans chiffre → validation bloque | ✅ |
| 3.10 | Password sans caractère spécial → validation bloque | ✅ |
| 3.11 | Email déjà enregistré → redirect login ou message d'erreur 🔑 | ✅ |

---

## §4 — Authentification — Mot de passe oublié

**Fichier** : `forgot_password.spec.ts` | **Projet** : `chromium`

| # | Test | Status |
|---|---|---|
| 4.1 | Page "Forgot password" accessible depuis login | ✅ |
| 4.2 | Champ email et bouton "Send Reset Code" présents | ✅ |
| 4.3 | Formulaire vide → validation bloque | ✅ |
| 4.4 | Email invalide → validation bloque | ✅ |
| 4.5 | Email inconnu → app ne crash pas | ✅ |
| 4.6 | Email valide → message de succès affiché 🔑 | ✅ |
| 4.7 | Bouton "Continue to reset password" visible après succès 🔑 | ✅ |
| 4.8 | Bouton "Back" / "Back to Login" → retour login | ✅ |

---

## §5 — Authentification — Reset password

**Fichier** : `reset_password.spec.ts` | **Projet** : `chromium`

| # | Test | Status |
|---|---|---|
| 5.1 | Page "Reset password" accessible depuis forgot password 🔑 | ✅ |
| 5.2 | Champs Email (pré-rempli), Code 6 chiffres, New password, Confirm présents 🔑 | ✅ |
| 5.3 | Formulaire vide → validation bloque 🔑 | ✅ |
| 5.4 | Code < 6 chiffres → validation bloque 🔑 | ✅ |
| 5.5 | Passwords différents → validation bloque 🔑 | ✅ |
| 5.6 | Nouveau password trop faible → validation bloque 🔑 | ✅ |
| 5.7 | Lien "Back to Login" → retour login 🔑 | ✅ |
| 5.8 | Reset réussi → retour à la page de login | 🔲 📧 |

---

## §6 — Authentification — Vérification email

**Fichier** : `email_verification.spec.ts` | **Projet** : `chromium`

| # | Test | Status |
|---|---|---|
| 6.1 | Page de vérification affiche 6 cases de saisie | ✅ |
| 6.2 | Bouton "Verify Code" désactivé avant saisie | ✅ |
| 6.3 | Bouton "Resend" visible | ✅ |
| 6.4 | Bouton "Back to Login" visible | ✅ |
| 6.5 | Email destinataire affiché sur la page | ✅ |
| 6.6 | Code erroné → message d'erreur | ✅ |
| 6.7 | Code valide → création compte + navigation vers app | 🔲 📧 |
| 6.8 | "Back to Login" → retour au login | ✅ |

---

## §7 — Première connexion — Ajout compte CoC

**Fichier** : `add_account.spec.ts` | **Projet** : `chromium-auth` 🔑

| # | Test | Status |
|---|---|---|
| 7.1 | Champ "Player Tag (#ABC123)" présent | ✅ |
| 7.2 | Bouton "Add account" (+) présent | ✅ |
| 7.3 | Texte "Welcome" ou "Manage your accounts" visible | ✅ |
| 7.4 | Bouton "Confirm" présent | ✅ |
| 7.5 | Bouton "Confirm" désactivé quand aucun compte n'est ajouté | ✅ |
| 7.6 | Saisie d'un tag dans le champ | ✅ |
| 7.7 | Tag inexistant → message d'erreur | ✅ |
| 7.8 | Tag valide → compte ajouté dans la liste 🎮 | ✅ |
| 7.9 | Bouton "Confirm" activé après ajout d'un compte 🎮 | ✅ |
| 7.10 | Compte ajouté → peut être supprimé de la liste 🎮 | 🔲 |
| 7.11 | Confirmer → charge les données → redirige vers MyHomePage 🎮 | ✅ |

---

## §8 — Session — Déconnexion

**Fichier** : `logout.spec.ts`, `settings.spec.ts` | **Projet** : `chromium-auth` 🔑

| # | Test | Status |
|---|---|---|
| 8.1 | Bouton "Log out" accessible depuis AddCocAccountPage | ✅ |
| 8.2 | Clic "Log out" → retour login (onglets Discord/Email) | ✅ |
| 8.3 | Après logout → bouton Login visible (session effacée) | ✅ |
| 8.4 | Logout depuis Settings (MyHomePage) → dialog de confirmation 🎮 | ✅ |
| 8.5 | Confirmer logout dans dialog → retour login 🎮 | ✅ |
| 8.6 | Annuler logout dans dialog → reste dans l'app 🎮 | ✅ |

---

## §9 — Dashboard (page principale)

**Fichier** : `dashboard_content.spec.ts` | **Projet** : `chromium-auth` 🔑 🎮

| # | Test | Status |
|---|---|---|
| 9.1 | Bottom nav visible (Dashboard, Clan, War) | ✅ |
| 9.2 | Account selector pill visible dans l'app bar | ✅ |
| 9.3 | Dashboard affiche plus de 10 éléments semantics (content cards) | ✅ |
| 9.4 | Switch Clan tab + retour Dashboard ne crash pas | ✅ |
| 9.5 | Switch War tab ne crash pas | ✅ |
| 9.6 | Ouverture du menu comptes (barrierLabel "Accounts") | ✅ |
| 9.7 | Fermeture menu comptes → retour dashboard | ✅ |
| 9.8 | Tap player card → ouvre page profil | ✅ |
| 9.9 | Pull-to-refresh ne crash pas | ⚠️ |
| 9.10 | Sélection d'un autre compte → dashboard se met à jour | 🔲 |

---

## §10 — Profil joueur

**Fichier** : `player_profile.spec.ts` | **Projet** : `chromium-auth` 🔑 🎮

| # | Test | Status |
|---|---|---|
| 10.1 | Page joueur accessible depuis dashboard | ✅ |
| 10.2 | Tabs Home Base, Builder Base, Achievements visibles | ✅ |
| 10.3 | Home Base affiche Heroes + Troops | ✅ |
| 10.4 | Switch onglet Achievements sans crash | ✅ |
| 10.5 | Switch onglet Builder Base sans crash | ✅ |
| 10.6 | Retour au dashboard fonctionnel | ✅ |
| 10.7 | Header : player tag visible (via E2E_TEST_COC_TAG) | ✅ |
| 10.8 | Page War Stats accessible | 🔲 |
| 10.9 | Page Legend accessible (si Legend League) | 🔲 |

---

## §11 — Page Clan

**Fichier** : `clan_page.spec.ts` | **Projet** : `chromium-auth` 🔑 🎮

| # | Test | Status |
|---|---|---|
| 11.1 | Onglet Clan accessible depuis la bottom nav | ✅ |
| 11.2 | Page Clan charge du contenu ou état "No clan" | ✅ |
| 11.3 | État "No clan" affiche message correct | ✅ |
| 11.4 | Card info clan visible (>8 semantics) | ✅ |
| 11.5 | Card Entrées/Sorties visible ou app stable | ✅ |
| 11.6 | Tap card clan → ouvre détail clan | ✅ |
| 11.7 | Retour depuis détail clan → page Clan | ✅ |
| 11.8 | Card "Clan Capital" visible (si disponible) | ✅ |
| 11.9 | Détail clan : liste membres chargée | ✅ |
| 11.10 | Pull-to-refresh ne crash pas | ✅ |
| 11.11 | Tap Clan Capital card → détail capital s'ouvre | ✅ |
| 11.12 | Tap membre dans détail clan → PlayerScreen s'ouvre | ✅ |

---

## §12 — Page War / CWL

**Fichier** : `war_page.spec.ts` | **Projet** : `chromium-auth` 🔑 🎮

| # | Test | Status |
|---|---|---|
| 12.1 | Onglet War/League accessible depuis la bottom nav | ✅ |
| 12.2 | Page War charge sans crash | ✅ |
| 12.3 | État "No clan" → message correct | ✅ |
| 12.4 | War History card visible si clan a des guerres | ✅ |
| 12.5 | État guerre actif (Preparation / War ended) | ✅ |
| 12.6 | Section CWL visible pendant la saison CWL | ✅ |
| 12.7 | Tap war card → ouvre détail guerre | ✅ |
| 12.8 | Tap War History → War Stats screen | ✅ |
| 12.9 | War detail : onglets Statistics / Events / Teams | ✅ |
| 12.10 | CWL detail : onglets Rounds / Teams / Members | ✅ |
| 12.11 | Pull-to-refresh ne crash pas | ✅ |

---

## §13 — Recherche (Search)

**Fichier** : `search.spec.ts` | **Projet** : `chromium-auth` 🔑

| # | Test | Status |
|---|---|---|
| 13.1 | Onglets Players et Clans présents | ✅ |
| 13.2 | Champ de saisie présent et accepte du texte | ✅ |
| 13.3 | Recherche `#2PP` → résultat ou loading sans crash | ✅ |
| 13.4 | Onglet Clans → recherche `#2JUCY9UY` sans crash | ✅ |
| 13.5 | Vider la recherche → état vide restauré | ✅ |
| 13.6 | Tag joueur connu → nom visible dans les résultats 🎮 | ✅ |
| 13.7 | Tag clan connu → nom visible dans les résultats 🎮 | ✅ |
| 13.8 | Tap résultat joueur → ouvre la page profil 🎮 | ✅ |
| 13.9 | Recherche sans résultat → état vide (pas de crash) | ✅ |
| 13.10 | Tap résultat clan → ouvre la page clan 🎮 | ✅ |

---

## §14 — Paramètres (Settings)

**Fichier** : `settings.spec.ts` | **Projet** : `chromium-auth` 🔑 🎮

| # | Test | Status |
|---|---|---|
| 14.1 | Page Settings accessible via avatar (MyHomePage) | ✅ |
| 14.2 | Email du compte visible dans la section Account 🔑 | ✅ |
| 14.3 | Section Préférences visible (langue, thème, notifs) | ✅ |
| 14.4 | Section Support visible (FAQ, Discord, Translate) | ✅ |
| 14.5 | Section About visible (licences, privacy policy) | ✅ |
| 14.6 | Sélecteur de langue ouvre un dialog / bottom sheet | ✅ |
| 14.7 | Toggle thème Dark/Light ne crash pas | ✅ |
| 14.8 | Bouton Logout visible dans Settings | ✅ |
| 14.9 | Logout → dialog de confirmation s'ouvre | ✅ |
| 14.10 | Annuler logout → reste dans Settings | ✅ |
| 14.11 | Confirmer logout → retour login | ✅ |
| 14.12 | Tap FAQ → FaqScreen s'ouvre | ✅ |
| 14.13 | Tap Notifications → NotificationSettingsPage s'ouvre | ✅ |

---

## §15 — Gestion des comptes CoC (depuis MyHomePage)

**Fichier** : `coc_account_management.spec.ts` | **Projet** : `chromium-auth` 🔑 🎮

| # | Test | Status |
|---|---|---|
| 15.1 | Page manage accessible via account pill → Manage | ✅ |
| 15.2 | Titre "Manage your accounts" visible | ✅ |
| 15.3 | Comptes CoC existants listés sur la page manage | ✅ |
| 15.4 | Bouton "Add account" (+) présent | ✅ |
| 15.5 | Bouton "Confirm" activé quand des comptes existent | ✅ |
| 15.6 | Champ player tag présent pour ajout | ✅ |
| 15.7 | Retour depuis manage → retour MyHomePage | ✅ |
| 15.8 | Réordonner les comptes (drag & drop) | 🔲 |
| 15.9 | Sélectionner un autre compte → dashboard change | 🔲 |

---

## §16 — Gestion du compte utilisateur (Account management auth)

**Fichier** : `settings.spec.ts` | **Projet** : `chromium-auth`

> Navigation : avatar → Settings → Account → **Connected Accounts**

| # | Test | Status |
|---|---|---|
| 16.1 | Tile "Connected Accounts" visible dans la section Account de Settings | ✅ |
| 16.2 | Page Connected Accounts affiche les tiles Discord et Email avec leur statut | ✅ |
| 16.3 | Formulaire "Link email" visible uniquement pour un compte Discord-only | 🔲 |

---

## §17 — Gestion des erreurs / Résilience

**Fichier** : `error_handling.spec.ts` | **Projet** : `chromium-auth`

| # | Test | Status |
|---|---|---|
| 17.1 | Page "Connection Problem" apparaît si API inaccessible au démarrage | ✅ |
| 17.2 | Page d'erreur affiche un bouton Retry | ✅ |
| 17.3 | Page d'erreur affiche un lien "Join Discord" | ✅ |
| 17.4 | Clic Retry → nouvelle tentative, app ne crash pas | ✅ |
| 17.5 | Erreur réseau ne déconnecte pas l'utilisateur | ✅ |
| 17.6 | Pull-to-refresh avec API bloquée → app reste stable | ✅ |
| 17.7 | Page maintenance affichée si API en maintenance | 🔲 |
| 17.8 | Token expiré → redirige vers login (pas de boucle infinie) | 🔲 |

---

## Récapitulatif

| Statut | Nombre |
|---|---|
| ✅ Implémenté | **121** |
| ⚠️ Partiel | **1** |
| 🔲 À faire | **8** |
| **Total** | **130** |

### Tests restants (🔲) — raisons techniques

| Test | Raison du blocage |
|---|---|
| §2.11 — compte non vérifié | Nécessite un compte spécifique en état "pending verification" |
| §5.8 — reset réussi | Accès à la boîte mail requis 📧 → débloquable avec IMAP |
| §6.7 — code de vérification valide | Accès à la boîte mail requis 📧 → débloquable avec IMAP |
| §7.10 — suppression de compte | Interaction drag/swipe complexe à automatiser |
| §9.10 — switch de compte actif | Nécessite plusieurs comptes CoC liés |
| §10.8 — War Stats accessible | Navigation profonde depuis profil joueur |
| §10.9 — Legend League | Nécessite joueur en Legend League |
| §15.8 — drag & drop reorder | Interaction drag complexe |
| §15.9 — switch compte → dashboard change | Nécessite plusieurs comptes CoC |
| §16.3 — Link email form | Nécessite un compte Discord-only (sans email auth) |
| §17.7 — page maintenance | Nécessite API en mode maintenance |
| §17.8 — token expiré | Nécessite manipulation du JWT expiré |

### Pour débloquer §5.8 et §6.7 (accès email)
Créer une adresse dédiée (ex: `e2etest@clashk.ing`) + serveur IMAP.
Ajouter secrets: `E2E_IMAP_HOST`, `E2E_IMAP_USER`, `E2E_IMAP_PASSWORD`.
L'helper Playwright lira le dernier email reçu via `imapflow` pour extraire le code.
