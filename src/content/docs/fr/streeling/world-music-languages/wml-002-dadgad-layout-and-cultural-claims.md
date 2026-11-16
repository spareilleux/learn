---
title: "DADGAD : faits sur l'accordage et affirmations culturelles"
description: "Musiques du monde et langues : DADGAD dans une réponse de GA sur les accordages — Musiques et langues du monde"
sidebar:
  label: WML-002 · DADGAD
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-002-dadgad-layout-and-cultural-claims.fr.md
---

:::note[Streeling University]
**WML-002** · Musiques du monde et langues : DADGAD dans une réponse de GA sur les accordages · intermédiaire · 35 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-002-dadgad-layout-and-cultural-claims.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-001](../../world-music-languages/wml-001-guitar-around-the-world/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/voicing-learning-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département des musiques du monde et des langues** | Niveau : intermédiaire | Étape : Albedo | Durée : 35 minutes | Brouillon français en attente de révision

## Objectifs

À l'issue de cette leçon, vous saurez lire un accordage à six cordes dans l'ordre utilisé par un skill de GA, vérifier ses différences avec l'accordage standard, distinguer l'ensemble des hauteurs des cordes à vide d'un style ou d'une interprétation, et signaler les propos culturels d'une source comme des affirmations qui demandent des preuves supplémentaires. Vous saurez aussi décrire ce qu'établit une recherche déterministe dans une table sans prendre son indice numérique de confiance pour une preuve d'autorité musicale ou culturelle.

## Question du projet et limites des preuves

Un guitariste demande à Guitar Alchemist (GA) : « Qu'est-ce que l'accordage DADGAD ? » Le skill [`AlternateTuningsSkill` à la révision fixée](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs) contient une entrée DADGAD et du code qui met en forme une réponse corde par corde. Cette entrée propose aussi une phrase « Pourquoi l'utiliser » qui associe cet accordage aux musiques celtiques, au folk modal et à un « jeu aux accents indiens ». **Quelles parties de cette réponse un guitariste peut-il vérifier dans la table des accordages, et lesquelles exigent de consulter des musiciens, des enregistrements ou des sources historiques ?** Cette leçon s'appuie sur le commit GA `dc2e74cbd992a298f67efb928b5b3754615e1924` pour toute affirmation concernant le code.

[WML-001](../../world-music-languages/wml-001-guitar-around-the-world/) présente plusieurs traditions de guitare. Ici, nous auditons une seule réponse destinée aux musiciens. Le code versionné et le [code source des tests](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.ML.Tests/Unit/AlternateTuningsSkillTests.cs) permettent une lecture reproductible des sources ; ils ne fournissent ni interprétation enregistrée en DADGAD ni preuve indépendante des associations culturelles citées. Le cycle de rédaction de la source anglaise n’a réalisé aucune session avec le chatbot GA, manipulation d’instrument ou étude auprès d’auditeurs, et n’a produit aucune traduction ; le présent fichier est un brouillon français dont la revue linguistique reste à faire.

## 1. Placer les cordes dans le bon ordre

Les remarques du skill indiquent explicitement **du grave à l'aigu**, soit de la corde 6 à la corde 1. Son tableau d'accordage standard est `E, A, D, G, B, E`, et son tableau DADGAD est `D, A, D, G, A, D`. Le code de mise en forme affiche les six notes dans cet ordre, numérote chaque ligne avec `6 - i` et indique les extrêmes grave et aigu. Il s'agit d'une convention propre à ce skill de GA, et non d'une convention logicielle universelle. Inverser le tableau conserverait les lettres, mais attribuerait de mauvaises notes aux cordes.

| Corde de guitare | 6 (grave) | 5 | 4 | 3 | 2 | 1 (aiguë) |
|---|---|---|---|---|---|---|
| Standard | E | A | D | G | B | E |
| Entrée DADGAD de GA | D | A | D | G | A | D |
| Variation en demi-tons | −2 | 0 | 0 | 0 | −2 | −2 |

Trois cordes changent par rapport à l'accordage standard de la source : la corde 6 E→D, la corde 2 B→A et la corde 1 E→D. Chacune descend d'un ton, soit deux demi-tons ; les cordes 5, 4 et 3 gardent leurs notes à vide. Le tableau permet de vérifier les *noms des notes visées* et les écarts. Il ne mesure pas l'accordage réel de l'instrument, ne précise pas la variation de tension d'une corde donnée et ne certifie pas qu'une guitare particulière est réglée de manière sûre pour cet accordage. Ce sont des vérifications pratiques distinctes.

Dans une autre langue, conservez à la fois la suite de notes et son sens de lecture. Une traduction qui indiquerait par erreur de l'aigu au grave modifierait la consigne tout en préservant chaque lettre. Afficher les numéros des cordes à côté de la suite réduit cette ambiguïté. La dénomination des notes doit elle aussi être révisée pour la langue cible ; le brouillon anglais ne fournit pas de terminologie de guitare approuvée en français, en espagnol ou dans d'autres langues.

### Exercice 1 — Lire le sens de l'accordage

À partir du skill à la révision fixée, placez `D A D G A D` sur les cordes 6 à 1. Quelles sont les notes à vide la plus grave et la plus aiguë, et pourquoi serait-il trompeur de présenter la suite à l'envers ?

> **Réponse :** Les cordes 6, 5, 4, 3, 2, 1 correspondent respectivement à D, A, D, G, A, D. Les deux cordes extérieures sont des D. Le code ordonne les notes du grave à l'aigu ; inverser la suite change la note attribuée à chaque corde numérotée, même lorsque des extrémités identiques rendent les premières et dernières lettres faussement rassurantes.

### Exercice 2 — Vérifier chaque changement

Comparez l'accordage standard `E A D G B E` de la source à son entrée DADGAD. Quelles cordes changent, de combien de demi-tons, et lesquelles restent identiques ?

> **Réponse :** Les cordes 6, 2 et 1 descendent chacune de deux demi-tons : E→D, B→A et E→D. Les cordes 5 A, 4 D et 3 G restent identiques. Le texte `VsStandard` du skill dit la même chose, et la différence ligne par ligne se déduit des deux tableaux.

## 2. Les cordes à vide expliquent une catégorie sonore, pas une culture

Faites sonner *sur le papier les cordes à vide indiquées* : D, A, D, G, A, D. En supprimant les doublons, il reste D, G et A. Par rapport à D, G est une quarte et A une quinte ; cet ensemble ne contient ni tierce F ni tierce F♯. Cela étaye la description concise « Dsus4 à vide » que le skill donne de l'ensemble des hauteurs sans appuyer sur les frettes. Cela ne précise ni rythme, ni ornement, ni mélodie, ni interprète, ni contexte culturel. Un enregistrement pourrait employer cet accordage tout en faisant très peu sonner les cordes à vide.

La même source contient une entrée distincte Open D : `D, A, D, F#, A, D`. Par rapport à DADGAD, seule la corde 3 change, passant de G à F♯, un demi-ton plus bas. Les notes distinctes à vide sont D, F♯ et A, soit la triade de D majeur. Cette comparaison permet en principe d'entendre la différence structurelle et de la vérifier dans le fichier. Elle ne prouve pas que toute musique jouée dans l'un de ces accordages utilise un seul vocabulaire harmonique. Les notes frettées, les slides, les bends, la position du capodastre et la technique peuvent modifier le résultat.

« DADGAD présente à vide un ensemble de notes d'accord suspendu à la quarte » est une affirmation déduite des noms des notes selon une convention courante de désignation des accords. « Ce guitariste joue une musique authentique de la tradition X » demanderait des preuves concernant l'œuvre, le musicien, le contexte communautaire et la pratique musicale. Le seul nom d'un accordage ne permet pas cette conclusion. Même si deux enregistrements utilisaient exactement les mêmes cordes à vide, les affirmations culturelles les concernant pourraient différer.

### Exercice 3 — Comparer deux accordages ouverts

Donnez les noms des notes distinctes des entrées DADGAD et Open D. Quelle corde diffère, de combien, et pourquoi la source décrit-elle leurs ensembles de notes à vide comme Dsus4 et D majeur, respectivement ?

> **Réponse :** DADGAD contient {D, G, A} ; Open D contient {D, F♯, A}. La corde 3 passe de G à F♯, soit un demi-ton vers le bas. Par rapport à D, D–G–A donne la fondamentale, la quarte et la quinte sans tierce ; « Dsus4 » décrit donc l'ensemble des notes à vide. D–F♯–A apporte la tierce majeure ; « D majeur » décrit donc l'ensemble des notes à vide d'Open D. Aucune de ces désignations n'identifie une tradition interprétée.

## 3. Lire la provenance de la réponse

`ExecuteAsync` teste les motifs des accordages nommés avant de tenter une recherche inversée sur six notes. L'expression régulière de DADGAD reconnaît le nom d'un seul tenant ou avec des traits d'union et le relie à la clé `dadgad` de la table. Lorsqu'un nom est reconnu directement, `AnswerTuning` affiche la suite du grave à l'aigu, les lignes des cordes, une explication `VsStandard` et le champ `Flavor` de l'entrée sous « Pourquoi l'utiliser ». Le résultat réussi définit `Confidence = 1.0f` et renvoie des chaînes de preuve qui nomment le skill et la recherche dans la table des accordages.

Cet indice de confiance appartient à la **réponse issue de la recherche dans la table** dans cette implémentation. Il ne constitue pas une probabilité indépendante que chaque phrase de `Flavor` soit historiquement ou culturellement juste. Une seule fonction met en forme les données mécaniques des notes et les propos descriptifs dans une même réponse ; cette mise en forme commune ne donne pas aux deux types d'affirmations le même appui. Le code ne fournit aucune citation à côté du champ `Flavor` de DADGAD. Cette leçon présente donc ce vocabulaire culturel comme *ce que dit la source*, et non comme un récit vérifié d'une tradition ou d'un musicien.

Le skill définit aussi `CanHandle(message) => false`, avec un commentaire précisant qu'il utilise un routage sémantique. Cette ligne ne prouve pas qu'un chatbot en fonctionnement achemine ici un message utilisateur donné. Le fichier de tests vérifie les recherches par nom et les recherches inversées pour certains accordages ainsi que des garde-fous concernant les altérations ; il ne contient pas de test de résultat propre à DADGAD. Nos résultats DADGAD sont déduits de la table et du code de mise en forme. Exécuter un test du skill à une révision fixée pour cette demande précise et vérifier une trace réelle du chatbot seraient des étapes de vérification distinctes.

### Exercice 4 — Interpréter la confiance dans ses limites

Une personne qui lit le code voit `Confidence = 1.0f` à côté d'une réponse DADGAD générée. Qu'établit le code à propos de cette valeur, et pourquoi ne peut-elle pas valider la phrase sur les musiques celtiques, le folk modal et le jeu « aux accents indiens » ? Cette source seule peut-elle prouver que le chatbot GA a montré la réponse à un utilisateur ?

> **Réponse :** `Result` attribue 1.0 à une réponse réussie de recherche dans la table et y joint des preuves désignant le skill et la table. `AnswerTuning` ajoute à cette réponse les propos non sourcés de `Flavor` ; la valeur numérique ne les vérifie pas indépendamment. `CanHandle` renvoie false et la leçon ne dispose d'aucune trace de routage ; la source ne peut donc pas prouver qu'un chatbot en fonctionnement a affiché cette réponse.

## 4. Traduire une affirmation sans en renforcer la portée

La phrase « Pourquoi l'utiliser » de l'entrée DADGAD indique que cet accordage est « apprécié pour les musiques celtiques, le folk modal et le jeu aux accents indiens » et cite des artistes ainsi qu'un enregistrement. Ces associations peuvent orienter une question, mais le code ne fournit à leur sujet ni analyse directe d'enregistrement ni histoire culturelle sourcée. L'expression « aux accents indiens » est particulièrement large : elle ne nomme ni musicien, ni genre, ni répertoire, ni région, ni technique. Elle ne doit pas devenir, dans la traduction, une affirmation selon laquelle cet accordage représenterait la musique indienne en général. La même prudence s'applique au mot « celtique », qui recouvre plusieurs communautés et pratiques musicales.

Une légende utile dans le produit peut distinguer les niveaux : « La table des accordages alternatifs de GA donne DADGAD comme D–A–D–G–A–D, cordes 6→1. Sa description facultative associe cet accordage à plusieurs styles ; ces associations n'ont pas été vérifiées ici. » Un musicien peut utiliser les notes indiquées pour chaque corde tout en connaissant le statut des propos culturels. Lors d'une localisation, préservez le sens de lecture numéroté, gardez les noms et les symboles d'accordage exacts, et demandez à un musicien ainsi qu'à une personne dont c'est la langue maternelle de réviser les mots désignant les traditions et les techniques. Une traduction fluide qui transforme « la source associe » en « ceci est authentique dans » modifie l'affirmation.

Pour une interprétation particulière, une affirmation culturelle plus forte exigerait un enregistrement ou une partition identifiés, un contexte fourni par les musiciens concernés ou des travaux de recherche, et une explication des caractéristiques comparées. Aucune interprétation n'a été analysée pendant ce cycle. La table des accordages ne permet pas non plus d'établir si les cordes, le réglage d'une guitare ou la technique du musicien rendent cette configuration confortable. Les conseils du produit doivent être évalués sur l'instrument et avec les personnes auxquelles ils s'adressent.

### Exercice 5 — Choisir un texte défendable

Quelle légende est étayée par le skill à la révision fixée ? **A :** « La table DADGAD de GA indique D–A–D–G–A–D du grave à l'aigu ; son texte descriptif associe cet accordage aux musiques celtiques, au folk modal et à un jeu “aux accents indiens”. » **B :** « DADGAD prouve que cet enregistrement est une musique indienne authentique. » Citez une vérification supplémentaire à effectuer avant de formuler une affirmation culturelle propre à un enregistrement.

> **Réponse :** A attribue correctement les notes et les associations à la source GA. B n'est pas étayée : ni la table des accordages ni une phrase non sourcée de `Flavor` n'identifient ou n'analysent un enregistrement, et elles ne valident pas son authenticité. Examinez une interprétation identifiée avec une expertise musicale ou culturelle pertinente et un critère explicite avant de formuler une affirmation plus précise, propre à cet enregistrement.

## Limites et prochaine vérification

Cette leçon est une lecture des sources à une révision fixée. Elle n'a exécuté ni `AlternateTuningsSkill`, ni routage de demande vers le chatbot ; elle n'a impliqué ni jeu sur une guitare, ni écoute d'enregistrement, ni validation de l'histoire culturelle et des associations avec des artistes. Les cinq exercices vérifient des faits issus des sources et des déductions explicites ; ils ne mesurent pas l'apprentissage. Une prochaine vérification consisterait à ajouter et à exécuter un test de recherche par nom DADGAD sur une compilation à révision fixée, à comparer une réponse capturée à ses champs source, puis à faire réviser séparément le texte culturel par les musiciens concernés et des réviseurs de langue maternelle. La revue de cette traduction, la révision du contenu par des personnes compétentes, les essais auprès d'apprenants, la synchronisation et la compilation de Learn, la lecture publique anonyme et la publication restent en attente.
