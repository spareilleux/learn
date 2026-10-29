---
module_id: sem-005-bind-scene-hits-to-crossing-identity
department: semiotics
course: "Relier les résultats de collision à l’identité des croisements"
level: intermediate
prerequisites: [sem-004-face-identity-under-reindexing]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Relier les résultats de collision à l’identité des croisements

> **Brouillon source rédigé par IA.** Les validations humaines par un spécialiste du domaine, un réviseur maîtrisant la langue et un apprenant restent à réaliser. La publication HTML publique du cours reste en attente.

[SEM-004](sem-004-face-identity-under-reindexing.md) distingue une référence matérielle d’une position dans un tableau. Un résultat de collision [Godot](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html) doit désigner son croisement source après sérialisation. Votre livrable est un audit d’identité. Consultez le [README du laboratoire](../../../../code/streeling/weave-godot/README.md), le [README des preuves](../../../../code/streeling/evidence/weave-scene-2026-10-22/README.md) et la [tâche de l’apprenant](../../../../code/streeling/evidence/weave-scene-2026-10-22/learner-task.md). Le README des preuves conserve les détails des exécutions et les échecs.

Résultat vérifié sous Windows : l’enregistrement, le chargement et les 36 sondes physiques ont réussi ; les contrôles d’échelle, de liaison du corps de collision et de parité redémarrée ont échoué aux vérifications nommées. Les anciens échecs du lanceur n’apportent aucune preuve sur la scène.

## 1. Nommer l’objet visé

L’[évaluateur](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) et la [spécification](https://raw.githubusercontent.com/GuitarAlchemist/Demerzel/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json), immuables, définissent l’échantillon synthétique `odd-tile-seam-a`. Répéter un motif de 3 × 3 sur 2 × 2 donne 36 croisements sur une grille de 6 × 6. La parité globale produit 0 violation d’adjacence ; la parité redémarrée en produit 12 et est rejetée avant la création de la scène.

`w3-f0` désigne le croisement `(3,0)` dans ce modèle source et cette révision du manifeste. Ce n’est pas une identité matérielle universelle qui survivrait à toute modification. L’adaptateur conserve ce signe dans les noms de nœuds et les métadonnées afin qu’un corps de collision rechargé puisse renvoyer au manifeste. Cette correspondance lui donne son sens.

### Exercice 1 — Compléter une référence

Un agent rapporte « le croisement 3 est incorrect ». Que faut-il ajouter pour pouvoir examiner ce signalement ?

> **Réponse :** Précisez l’échantillon, l’empreinte source/du manifeste, l’ID stable tel que `w3-f0`, la propriété attendue et le résultat observé. Un entier seul pourrait désigner une case de tableau, une coordonnée de grille ou un identifiant d’exécution. Explicitez l’interprétation avant de signaler un défaut.

## 2. Distinguer trois sortes d’adresse

Un ID source désigne le croisement visé dans le manifeste déclaré. Un chemin de nœud situe un nœud dans une hiérarchie de scène particulière. Un ID d’instance à l’exécution identifie un objet actuellement instancié dans le moteur. Renommer un nœud ou changer son parent peut modifier son chemin sans changer le croisement visé. Libérer puis recharger une scène crée de nouveaux objets ; leurs ID d’instance ne sont pas censés préserver l’identité source.

L’essai utilise [PackedScene](https://docs.godotengine.org/en/4.6/classes/class_packedscene.html) avec propriétaires et métadonnées explicites, enregistre, libère l’original et recharge une nouvelle instance. Il attend 36 parents de croisement et 72 maillages, corps et formes de collision de chaque catégorie. Les ID de ressources à l’exécution servent à compter deux ressources partagées par catégorie de maillage, forme et matériau ; ce ne sont pas des étiquettes de provenance des croisements. L’ordre d’énumération d’un tableau constitue encore une autre adresse, sans garantie d’identité.

### Exercice 2 — Suivre le référent

Après rechargement, un corps a un nouvel ID d’exécution, mais conserve la métadonnée `crossing_id = w3-f0`. La conservation d’identité est-elle réfutée ?

> **Réponse :** Non. Le remplacement des objets à l’exécution est attendu. Vérifiez les métadonnées rechargées par rapport au bon manifeste source et à la cible de la sonde. Une chaîne identique sans provenance ni correspondance ne suffit pas, mais l’égalité des anciens et nouveaux ID d’exécution n’est pas requise.

## 3. Séparer les prédicats

[PhysicsDirectSpaceState3D.intersect_ray](https://docs.godotengine.org/en/4.6/classes/class_physicsdirectspacestate3d.html) renvoie un résultat dont les métadonnées du corps touché portent `crossing_id` et `strand`. L’essai lance 36 rayons descendants aux centres attendus. Trois prédicats distincts comptent : la racine rechargée correspond à l’empreinte du manifeste source ; le résultat désigne le croisement ciblé ; son brin est le brin supérieur attendu. Avec la phase zéro, `w2-f0` attend la chaîne et `w3-f0` la trame.

Une empreinte lie des octets exacts, pas une vérité. Ces octets peuvent décrire un motif rejeté ; l’admission sémantique s’en charge. Une identité correcte ne prouve pas le bon dessus/dessous, et une étiquette de brin correcte ne prouve pas l’identité du croisement. Des prédicats distincts rendent les échecs instructifs.

### Exercice 3 — Lire des preuves mixtes

À `w3-f0`, le résultat indique `crossing_id = w2-f0` et `strand = weft` ; l’empreinte de la racine correspond. Quels prédicats peuvent encore réussir ?

> **Réponse :** La liaison au manifeste et l’attente du brin supérieur peuvent réussir. `ray_crossing_identity` échoue puisque le croisement demandé est `w3-f0`. Les deux prédicats réussis ne corrigent pas la fausse référence ; conservez les trois observations.

## 4. Rompre volontairement la liaison

Dans une copie temporaire, changez uniquement l’affectation `crossing_id` du corps statique pour un mauvais ID. Conservez géométrie, manifeste et affectation du brin. La vérification nommée `ray_crossing_identity` doit échouer même si les prédicats de position et de dimension réussissent. Ce contrôle vérifie que le vérificateur remarque un faux référent, au-delà de la simple détection d’une surface.

Avec [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), [Python](https://docs.python.org/3/using/cmdline.html) et Godot 4.6.1 installés et accessibles dans `PATH`, choisissez une nouvelle sortie hors du checkout :

```text
node code/streeling/weave-godot/run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json
```

La commande est commune aux systèmes ; Windows a été essayé, Linux/WSL et macOS restent à vérifier. Conservez empreintes et journaux d’échec. Un dépassement du délai de démarrage est un problème d’environnement ou d’exécution, pas une preuve d’acceptation ou de rejet de la modification par le prédicat d’identité. Il n’apporte aucune nouvelle preuve sur la scène.

### Exercice 4 — Protéger le contrôle

Déplacer le corps de collision tout en changeant son ID isolerait-il un défaut de liaison d’identité ?

> **Réponse :** Non. Deux interventions peuvent causer une absence de collision ou un mauvais résultat pour des raisons différentes. Changez seulement l’affectation de métadonnée, relancez et conservez l’échec nommé. Si l’exécution échoue avant les requêtes, indiquez que le contrôle n’a pas été évalué.

## 5. Borner la conclusion sur la communication

Ces boîtes isolées représentent la chaîne selon Z et la trame selon X ; elles n’établissent pas un fil continu. Des résultats physiques automatisés ne sont ni des clics humains, ni des surbrillances réussies, ni une compréhension par l’apprenant. Une scène peut réussir les 36 requêtes tout en restant visuellement confuse.

Traitez la composabilité comme une hypothèse : observez, changez une liaison, relancez, conservez le contre-exemple et précisez la frontière testée. Un manifeste simple et une grille 2D étiquetée constituent des alternatives crédibles. Cet exercice ne donne aucune raison universelle d’adopter un DSL ni d’attendre une progression exponentielle avec le nombre d’outils.

### Exercice 5 — Concevoir la prochaine observation

Que demanderait un véritable essai auprès d’un apprenant au-delà d’un rapport de requêtes réussi ?

> **Réponse :** Une tâche fixe désignant un croisement et son brin supérieur, les réponses recueillies sans aide et une comparaison avec la référence 2D étiquetée. L’interaction humaine, la validation du domaine, la révision linguistique et la publication restent des travaux distincts en attente. Un résultat scripté ne prouve que la correspondance source-corps de collision spécifiée pour les octets testés.
