# Plan d'implémentation

Ce document liste les issues dans l'ordre d'implémentation défini par leurs phases et sections.


## Phase 1: Rôle et positionnement


### Ce qu'il ne fait pas

- [ ] #500: **Aucun entraînement** : rien dans ce dépôt ne modifie un poids
- [ ] #501: Pas d'orchestration, pas de requête réseau, pas de persistance :
- [ ] #521: Pas de logique d'orchestration, d'évaluation ni d'agrégation : il
- [ ] #522: Pas d'interprétation des contenus : un `content` HTTP est un
- [ ] #523: Pas de décision sur les données : un doublon (`checksum`) est
- [ ] #524: Pas de décision d'autorisation : il sert le registre des clés

### Ce que ce translator garantit aux autres

- [ ] #497: **Un contrat de commandes gelé** : statut, topologie, entrées,
- [ ] #498: **Reproductibilité** : un montage frais porte des poids
- [ ] #499: **Remplaçabilité** : tout backend de calcul qui respecte le même
- [ ] #517: **Un seul point d'entrée SQL** : `data-base-translator` est
- [ ] #518: **Durabilité dès la première exécution** : toute donnée écrite par
- [ ] #519: **Rejouabilité** : ce qui a été acquis sur le réseau ou calculé
- [ ] #520: **Clés privées jamais vues** : le registre du mode distant

### Définitions des quatre rôles de l'orchestrateur

- [ ] #680: **Scheduler (ordonnanceur)** : décide *quand* et *combien* d'instances
- [ ] #681: **Supervisor (superviseur)** : surveille les instances en cours
- [ ] #682: **Evaluator (évaluateur)** : compare les sorties des différentes
- [ ] #683: **Aggregator (agrégateur)** : à partir des sorties et des scores,

### Les deux faces du même rôle

- [ ] #602: **Face POSIX** (translator `/inference`) : un prompt soumis par
- [ ] #603: **Face interactive** (client `inference`) : une IHM en ligne de

### Les deux modes de déploiement

- [ ] #604: **Mode local** : tout tourne sur la machine ; le translator est
- [ ] #605: **Mode distant** : la pile GNU AI (inference, orchestrateur,

## Phase 2: Fonctionnalités principales


### Non classée

- [ ] #502: **Efficacité mémoire** : stockage `float32` (4 octets au lieu de
- [ ] #503: , bloc unique contigu pour tout le réseau (arena allocator),
- [ ] #504: **Efficacité CPU** : accès mémoire séquentiels (cache-friendly),
- [ ] #505: **Pilotage POSIX complet** :
- [ ] #506: lecture du statut du réseau et de la sortie courante par un
- [ ] #507: configuration de la topologie (`echo '3,5,2' > /llm`, couches
- [ ] #508: fourniture des entrées (le nombre de valeurs doit correspondre
- [ ] #509: `save <fichier>` / `load <fichier>` : sérialisation du réseau
- [ ] #510: `reset` : ré-amorçage de l'état volatile (voltages, compteurs)
- [ ] #511: **Modèle** : activation sigmoïde f(x) = 1 / (1 + exp(-x)), réseau
- [ ] #525: *Translator monté sur `/db`** : pilotable par les commandes POSIX
- [ ] #526: *Création idempotente du schéma** : au montage, les tables
- [ ] #527: *Écriture d'enregistrements** : une ligne JSON soumise par
- [ ] #528: *Lecture de requêtes** : une requête soumise par `write` (filtres,
- [ ] #529: *Anti-doublon SHA-256** : la contrainte `UNIQUE` sur
- [ ] #530: *Navigation par arborescence** : `/db/runs/<id>`,
- [ ] #531: *État et diagnostic** : `/db/status` (connexion au serveur,
- [ ] #532: *Registre des clés SSH** : enregistrement des clés **publiques**
- [ ] #606: *Réception des prompts** : saisie multi-lignes interactive ou
- [ ] #607: *Éditeur intégré** : composition du prompt dans n'importe quel
- [ ] #608: *Explication des actions** : à la manière des agents CLI
- [ ] #609: *Trois requêtes JSON structurées** (le cœur du contrat,
- [ ] #610: *Extraction structurée** : URLs (expression rationnelle), type de
- [ ] #611: *Interface en couleurs et animations** : code d'échappement ANSI
- [ ] #612: *Coloration syntaxique** : le prompt affiché distingue texte,
- [ ] #613: *Affichage en streaming** : lecture incrémentale de `status`
- [ ] #614: *Mode distant datacenter/cluster** : le client ouvre une
- [ ] #615: *Interface translator** : `/inference` reste pilotable en pur
- [ ] #684: *Multi-instanciation** : lancer N `neuron-translator` sur des
- [ ] #685: *Distribution des entrées** : envoyer le même vecteur d'entrée
- [ ] #686: *Collecte et comparaison** : lire les sorties de chaque instance,
- [ ] #687: *Agrégation** : produire un résultat final pondéré ou voté.
- [ ] #688: *Acquisition de données par le réseau** : une URL fournie *dans le
- [ ] #689: *Persistance PostgreSQL** : les données d'entraînement récupérées
- [ ] #690: *Interface translator** : l'orchestrateur est lui-même un

## Phase 3: Architecture et flux de données


### 3.2 Flux nominal d'un enregistrement

- [ ] #533: L'orchestrateur monte `data-base-translator` sur `/db` (par ex.
- [ ] #534: Au démarrage, le translator vérifie la connexion, crée ou
- [ ] #535: L'orchestrateur écrit une ligne JSON :
- [ ] #536: Le translator traduit la ligne en requête préparée, l'exécute,
- [ ] #537: Pour relire : l'orchestrateur écrit une requête

### 3.2 Flux nominal d'une requête

- [ ] #691: Un prompt contenant une ou plusieurs URL est soumis à
- [ ] #692: `inference-translator` expose la requête structurée (type 1,
- [ ] #693: L'orchestrateur monte (ou réutilise) une instance `httpfs` avec
- [ ] #694: Le contenu récupéré est normalisé en vecteurs d'entrée et archivé
- [ ] #695: Le scheduler démarre ou sélectionne N instances de
- [ ] #696: L'evaluator compare les sorties, l'aggregator produit le résultat
- [ ] #697: Exécution, sorties et décision sont archivés dans PostgreSQL ;

### 3.2 bis Flux nominal d'une clé SSH (mode distant d'inference)

- [ ] #538: L'opérateur du cluster enregistre la clé **publique** SSH d'un
- [ ] #539: Le translator calcule l'empreinte SHA-256 de la clé publique,
- [ ] #540: Le serveur `inference` lit le registre actif
- [ ] #541: Chaque échec d'authentification SSH est journalisé par le
- [ ] #542: Révoquer, c'est écrire une date : `{ "revoke": "access_keys",

### 3.5 Mode distant : SSH, protocole à trames et clés

- [ ] #616: **Session** : `inference --remote utilisateur@hôte` exécute
- [ ] #617: **Chiffrement et authentification : délégués à OpenSSH** — aucun
- [ ] #618: **Poignée de main** : à l'ouverture, le client envoie
- [ ] #619: Clés SSH standard (ed25519 recommandé), une identité par
- [ ] #620: **Enregistrées par l'opérateur** du datacenter/cluster dans le
- [ ] #621: **Révocables côté serveur** : révoquer une clé dans le registre
- [ ] #622: Chaque échec d'authentification SSH est journalisé côté serveur

### Flux nominal d'une inférence

- [ ] #512: `settrans /llm …` : montage, `network_init()` alloue l'arena
- [ ] #513: `write` d'une topologie : réallocation de l'arena à la nouvelle
- [ ] #514: `write` des entrées : forward pass (`network_forward()`) sans
- [ ] #515: `load model.nn` (optionnel) : remplace les poids par ceux d'un
- [ ] #516: `save result.nn` : rediffusion du réseau courant vers un autre

## Phase 4: Décisions de conception (réponses aux points en suspens)


### Faut-il modifier `neuron-translator` ?

- [ ] #698: un fichier `stats` lisible (compteurs de passes, erreurs) pour
- [ ] #699: la possibilité de fixer/lire la graine des poids initiaux, pour la

## Phase 4: Décisions de conception


### Le cluster dès la phase 3 : concurrence mesurée, registre anticipé

- [ ] #546: Le **verrou sur la connexion libpq** est le mécanisme par
- [ ] #547: Les tables `users` et `access_keys` sont créées dès la phase 3
- [ ] #548: Aucune écriture ne doit laisser d'état partiel visible, quel

## Phase 4: Décisions de conception (réponses aux points en suspens)


### Ne pas prévoir la base de données dès le départ n'est-il risqué ?

- [ ] #700: l'implémentation **par défaut** s'appuie sur `data-base-translator`
- [ ] #701: une implémentation **en mémoire** existe uniquement pour les tests

## Phase 4: Décisions de conception


### Pourquoi un translator, et non une bibliothèque liée à l'orchestrateur ?

- [ ] #543: **remplaçabilité** : le serveur PostgreSQL (hôte, version,
- [ ] #544: **partage** : plusieurs translators écrivent dans la même base
- [ ] #545: **inspection** : l'état de la persistance est lisible par

## Phase 5: Phases


### Phase 0 — Spécification et contrats (avant tout code)

- [ ] #549: Reprise du contrat `orchestrator → database` gelé par
- [ ] #550: Reprise du contrat `inference → database` (registre des clés
- [ ] #551: Gel de l'arborescence `/db` : `status`, `schema`,
- [ ] #552: Implémentation de référence du schéma SQL de la section 6 (fichier
- [ ] #553: Convention d'arguments de montage : `conninfo` libpq, options de
- [ ] #554: **Livrable** : `SPEC.md` + squelette de code compilable.
- [ ] #555: **Acceptation** : revue croisée du contrat avec
- [ ] #623: Gel du **trio de requêtes JSON** `request`/`status`/`result`
- [ ] #624: Gel du mode distant : transport SSH (commande serveur, arguments,
- [ ] #625: Protocole éditeur : ordre de résolution `$VISUAL` → `$EDITOR` →
- [ ] #626: Palette et conventions d'affichage (codes ANSI, thèmes de base,
- [ ] #627: Convention des points de montage : `/inference`, `/orchestrate`.
- [ ] #628: **Livrable** : `SPEC.md` + squelette de code compilable.
- [ ] #629: **Acceptation** : revue croisée des contrats avec
- [ ] #702: Gel des contrats d'interface de la section 3.3.
- [ ] #703: Format du descripteur de tâche (JSON simple en ligne) :
- [ ] #704: Schéma PostgreSQL (voir section 6) : gelé ici, **utilisé dès la
- [ ] #705: Couche stockage : interface unique `storage_write`/`storage_read`,
- [ ] #706: Convention des points de montage : `/llm<N>`, `/web`, `/inference`,
- [ ] #707: Gel du trio JSON `request`/`status`/`result` avec
- [ ] #708: **Livrable** : `SPEC.md` + squelette de code compilable.
- [ ] #709: **Acceptation** : revue des contrats avec les dépôts voisins,

### Phase 1 — MVP : le translator `/inference` (mode local)

- [ ] #630: Translator monté via `settrans` sur `/inference`.
- [ ] #631: `write` du prompt sur `/inference/prompt` ; extraction des URLs
- [ ] #632: `read` de `/inference/request` (type 1), `/inference/urls`,
- [ ] #633: Détection heuristique minimale de la tâche (mots-clés : « résume »,
- [ ] #634: **Livrable** : `inference-translator` compilable sous Hurd, tests
- [ ] #635: **Acceptation** : un prompt contenant une URL produit une requête

### Phase 1 — MVP : orchestration de base avec persistance PostgreSQL

- [ ] #710: Scheduler : démarrer/arrêter N `neuron-translator` sur `/llm1…
- [ ] #711: Distribution d'un vecteur d'entrée à toutes les instances, collecte
- [ ] #712: Aggregator : vote majoritaire et moyenne uniforme.
- [ ] #713: Translator `/orchestrate` minimal : `run` (lancer un descripteur de
- [ ] #714: **Persistance dès la première exécution** : chaque `run`
- [ ] #715: **Livrable** : `orchestrator-translator` compilable sous Hurd, testé
- [ ] #716: **Acceptation** : une exécution complète sur Debian GNU/Hurd

### Phase 1 — MVP : schéma + écritures

- [ ] #556: Connexion libpq au montage, création idempotente du schéma
- [ ] #557: Écriture de `runs`, `run_instances` et `training_data` via
- [ ] #558: Signalement du doublon `checksum` comme statut `duplicate`.
- [ ] #559: **Livrable** : `data-base-translator` compilable sous Hurd, monté
- [ ] #560: **Acceptation** : la phase 1 d'`orchestrator-translator`

### Phase 2 — Incidents et lectures

- [ ] #561: Écriture de `incidents` (crash, timeout, restart) — le supervisor
- [ ] #562: Requêtes en lecture : `select` avec filtres simples et tri
- [ ] #563: `/db/runs/<id>` et `/db/runs/<id>/instances` navigables
- [ ] #564: **Livrable** : contrat `read` complet du gel de phase 0.
- [ ] #565: **Acceptation** : l'historique d'une exécution survivante à une

### Phase 2 — Le client `inference` : IHM minimale

- [ ] #636: Bannière colorée, saisie multi-lignes (mode brut `termios`),
- [ ] #637: Intégration `$EDITOR` : composition du prompt dans nano/vim/emacs,
- [ ] #638: Narration des actions avec le nœud POSIX concerné à chaque étape.
- [ ] #639: **Livrable** : client `inference` fonctionnel contre le translator
- [ ] #640: **Acceptation** : un utilisateur compose un prompt dans son éditeur,

### Phase 2 — Supervisor et parallelisme

- [ ] #717: Surveillance des instances : détection de non-réponse (timeout),
- [ ] #718: Exécution parallèle de plusieurs tâches ; file d'attente de
- [ ] #719: Limites de ressources : nombre max d'instances simultanées.
- [ ] #720: **Livrable** : supervisor opérationnel + tests de défaillance
- [ ] #721: **Acceptation** : une tâche survit à la perte d'une instance et

### Phase 3 — Acquisition réseau : inference + httpfs

- [ ] #722: Lecture de la requête structurée `/inference/request` (type 1) via
- [ ] #723: Montage dynamique de `httpfs` sur l'URL, lecture de `content` et
- [ ] #724: Transformation du contenu récupéré en vecteurs d'entrée
- [ ] #725: Chaque contenu récupéré est archivé comme donnée d'entraînement
- [ ] #726: **Mode cluster dès cette phase** : l'orchestrateur peut lancer
- [ ] #727: **Livrable** : une tâche complète "prompt → URL → contenu →
- [ ] #728: **Acceptation** : démonstration de bout en bout avec une URL réelle

### Phase 3 — Acquisition réseau servie : `training_data`

- [ ] #566: Support des gros contenus : écriture et lecture paginées du champ
- [ ] #567: Archivage des contenus récupérés via `httpfs-translator`
- [ ] #568: Requêtes par plage de date, par statut HTTP, par absence en base
- [ ] #569: **Mode cluster dès cette phase** : écritures et lectures
- [ ] #570: **Livrable** : une tâche complète de la phase 3 orchestrateur
- [ ] #571: **Acceptation** : les deux traces d'une démonstration orchestrateur

### Phase 3 — Interface riche : couleurs, animations, streaming

- [ ] #641: Coloration syntaxique du prompt (URLs, markdown léger) et des
- [ ] #642: Animations : spinner pendant l'attente du `result`, effet machine
- [ ] #643: Lecture incrémentale de `status` (type 2) puis du `result`
- [ ] #644: **Mode cluster dès cette phase** : le client `inference` peut
- [ ] #645: **Livrable** : IHM complète contre un orchestrateur simulé par
- [ ] #646: **Acceptation** : démonstration visuelle sans scintillement

### Phase 4 — Intégration de bout en bout avec l'orchestrateur

- [ ] #647: Scénario complet : prompt (éditeur) → `request` → orchestrateur
- [ ] #648: Affichage du `status` (instances démarrées, états, scores) comme
- [ ] #649: **Livrable** : démonstration de bout en bout sur Debian GNU/Hurd.
- [ ] #650: **Acceptation** : le même prompt fonctionne via l'IHM et via

### Phase 4 — Rejouabilité : exports et historique

- [ ] #572: Export d'un jeu d'entraînement archivé sous forme de flux de
- [ ] #573: Historique et statistiques : performances par topologie calculées
- [ ] #574: Pagination et limites de mémoire bornées sur toutes les lectures.
- [ ] #575: **Livrable** : commandes d'export et d'historique du contrat.
- [ ] #576: **Acceptation** : rejouer une tâche de la phase 3 orchestrateur à

### Phase 4 — Rejouabilité : lecture et requêtes dans la base

- [ ] #729: Relecture des jeux d'entraînement archivés pour rejouer une tâche
- [ ] #730: Rejeu d'une exécution : mêmes descripteurs, mêmes entrées,
- [ ] #731: Historique consultable : performances par topologie à partir des
- [ ] #732: **Livrable** : commandes `replay` et `history` du translator
- [ ] #733: **Acceptation** : rejouer une tâche de la phase 3 à partir des

### Phase 5 — Evaluator avancé et boucle d'amélioration

- [ ] #734: Scores par instance (accord inter-instances, comparaison à la
- [ ] #735: Sélection automatique de topologies : conserver les configurations
- [ ] #736: Statistiques demandées à `neuron-translator` (fichier `stats`,
- [ ] #737: **Livrable** : agrégation pondérée apprise.
- [ ] #738: **Acceptation** : sur un jeu de test étiqueté, la sortie agrégée

### Phase 5 — Mode distant : SSH, datacenter et cluster local

- [ ] #651: Processus `inference-serveur` lancé par session SSH
- [ ] #652: Registre des clés publiques SSH nominatives dans PostgreSQL via
- [ ] #653: Côté client : `inference --remote utilisateur@hôte`
- [ ] #654: **Livrable** : une pile GNU AI complète exécutée sur un cluster
- [ ] #655: **Acceptation** : le même prompt donne le même résultat en mode

### Phase 5 — Registre des clés SSH (mode distant d'inference-translator)

- [ ] #577: Écriture de `users` et `access_keys` : enregistrement d'une clé
- [ ] #578: Lecture du registre actif par le serveur `inference` pour
- [ ] #579: Révocation par simple écriture d'une date (`revoked_at`) puis
- [ ] #580: Journal des échecs d'authentification SSH : chaque connexion
- [ ] #581: Navigation : `/db/users`, `/db/access_keys` lisibles
- [ ] #582: **Livrable** : registre de clés complet, servi uniquement via
- [ ] #583: **Acceptation** : une session SSH authentifiée par une clé du

### Phase 6 — Durcissement, tests, CI

- [ ] #584: Reconnexion automatique au serveur PostgreSQL, comportement en
- [ ] #585: Suite de tests déterministes : schéma embarqué sur instance
- [ ] #586: CI sous QEMU GNU/Hurd, pilotée par le sandbox
- [ ] #587: Documentation utilisateur et architecture (`docs/architecture.md`).
- [ ] #588: **Livrable** : version 1.0.
- [ ] #739: Suite de tests déterministes (serveur HTTP embarqué sur boucle
- [ ] #740: CI sous QEMU GNU/Hurd, pilotée par le sandbox
- [ ] #741: Documentation utilisateur et architecture (`docs/architecture.md`).
- [ ] #742: **Livrable** : version 1.0.

### Phase 6 — Historique et ergonomie de session

- [ ] #656: Historique des prompts de la session (navigation, ré-édition dans
- [ ] #657: Commandes `history`, `replay` côté client, cohérentes avec les
- [ ] #658: **Livrable** : session interactive complète multi-requêtes.
- [ ] #659: **Acceptation** : rejouer une requête précédente depuis l'IHM

### Phase 7 — Durcissement, tests, CI

- [ ] #660: Tests déterministes du translator (suites POSIX sans terminal),
- [ ] #661: Tests du mode distant : sshd de test sur boucle locale, clé
- [ ] #662: CI sous QEMU GNU/Hurd, pilotée par le sandbox
- [ ] #663: Documentation utilisateur (`docs/interface.md`, `docs/remote.md`)
- [ ] #664: **Livrable** : version 1.0.

## Phase 6: Contraintes et conventions techniques


### Non classée

- [ ] #665: **Langue du code et des commentaires** : anglais, style Claude
- [ ] #666: **C23 / POSIX.1-2008**, bibliothèques Hurd (`trivfs` pour le MVP,
- [ ] #667: **Zéro allocation dans les chemins chauds** : les chemins d'affichage
- [ ] #668: **Multitâche et multi-utilisateurs** : le translator doit accepter
- [ ] #669: **Pas de dépendance TUI** : ANSI + `termios` uniquement ; `NO_COLOR`
- [ ] #670: **Zéro bibliothèque de chiffrement** : le mode distant invoque le
- [ ] #671: **Interface muette côté translator, narration côté client** :
- [ ] #672: **Erreurs réseau ≠ erreurs POSIX** : un statut HTTP non-200 vu dans
- [ ] #673: **Clés SSH : standard OpenSSH** ; la partie privée ne quitte jamais
- [ ] #674: Chaque translator reste remplaçable : l'interface ne connaît que

### Stratégie de tests unitaires

- [ ] #675: **Harnais maison minimal** : macros `CHECK` et compteurs en
- [ ] #676: **Le noyau d'extraction d'abord** : détection d'URLs, détection de
- [ ] #677: **Le contrat POSIX est le premier test** :
- [ ] #678: **Client sans décor parasite** : tests via pseudo-terminaux ; en
- [ ] #679: **Mode distant isolé** : sshd de test sur boucle locale (clé

## Phase 7: Contraintes et conventions techniques


### Non classée

- [ ] #589: **Langue du code et des commentaires** : anglais, style Claude
- [ ] #590: **C23 / POSIX.1-2008**, bibliothèques Hurd (`trivfs` pour le MVP,
- [ ] #591: **`libpq` uniquement**, requêtes préparées, aucune construction de
- [ ] #592: **Zéro allocation dans les chemins chauds** : requêtes préparées
- [ ] #593: **Multitâche et multi-utilisateurs** : le translator doit servir
- [ ] #594: **Contraintes SQL ≠ erreurs POSIX** : doublon, absence de ligne,
- [ ] #595: **Clés privées jamais vues** : le registre ne stocke que des clés
- [ ] #596: Chaque translator reste remplaçable : l'orchestrateur ne connaît
- [ ] #743: **Langue du code et des commentaires** : anglais, style Claude
- [ ] #744: **C23 / POSIX.1-2008**, bibliothèques Hurd (`trivfs` pour le MVP,
- [ ] #745: **Zéro allocation dans les chemins chauds**, mémoire contiguë,
- [ ] #746: **Multitâche et multi-utilisateurs** : l'orchestrateur doit piloter
- [ ] #747: **Erreurs réseau ≠ erreurs POSIX** : un statut HTTP non-200 est une
- [ ] #748: **Mode distant sans impact** : ni SSH, ni clés, ni port d'écoute —
- [ ] #749: Chaque translator reste remplaçable : l'orchestrateur ne connaît que

### Stratégie de tests unitaires

- [ ] #597: **Harnais maison minimal** : macros `CHECK` et compteurs en
- [ ] #598: **Instance jetable** : la suite crée et détruit sa propre base de
- [ ] #599: **Contraintes comme statuts** : doublon de `checksum`, absence de
- [ ] #600: **Transaction sur chaque écriture** : à la manière des tests de
- [ ] #601: **Pagination bornée** : lectures paginées vérifiées sur des
- [ ] #750: **Harnais maison minimal** : macros `CHECK` et compteurs en
- [ ] #751: **Un rôle, une suite** : scheduler, supervisor, evaluator et
- [ ] #752: **Stockage mémoire pour les tests** : le backend `storage_write` /
- [ ] #753: **Réseau simulé, jamais réel** : serveur HTTP embarqué sur boucle
- [ ] #754: **Déterminisme** : descripteurs et entrées figés ; aucune horloge
