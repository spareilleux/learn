---
title: Symboles d'accords, canonicalisation et sens dans le DSL de GA
description: Symboles d’accords, canonicalisation et sens dans le DSL de GA — Sémiotique
sidebar:
  label: SEM-002 · Symboles d'accords, canonicalisation et sens dans le DSL de GA
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/fr/sem-002-chord-symbols-and-canonicalization.fr.md
---

:::note[Streeling University]
**SEM-002** · Symboles d’accords, canonicalisation et sens dans le DSL de GA · intermédiaire · 35 minutes

Généré par le département *Sémiotique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/fr/sem-002-chord-symbols-and-canonicalization.fr.md) · [Mon journal](../../journal/)

Prérequis: [SEM-001](../../semiotics/sem-001-signs-in-governance/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques de traductions encore à rédiger, d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) décrit les brouillons de traduction actuels, l’importation et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de sémiotique** | Niveau : intermédiaire | Étape : Albedo | Durée : 35 minutes | Brouillon français ; révision en attente, notamment par une personne maîtrisant le français

## Objectifs

Après cette leçon, vous saurez identifier le signe saisi, la structure d'accord analysée, le rendu canonique et la projection en classes de hauteurs dans Guitar Alchemist (GA). Vous suivrez cinq exemples fixes dans le code ou les tests figés, distinguerez équivalence lexicale et interprétation musicale, et concevrez des libellés indiquant quelle transformation a produit chaque valeur.

## La question du projet

Supposons qu'un guitariste saisisse `Cmi7` dans un outil GA. Un résultat en aval affiche `Cm7`. GA a-t-il écouté une interprétation, changé l'accord ou normalisé un symbole écrit ? L'[analyseur d'accords](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Parsers/ChordParser.fs), le [générateur de rendu](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Generators/ChordRenderer.fs) et le [service](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Services/ChordDslService.fs) figés répondent à une question plus restreinte et utile : **Quelles distinctions de la notation saisie survivent à l'analyse et au rendu canonique, et lesquelles disparaissent lors d'une projection ?** Tous les liens GA de cette leçon figent le commit `dc2e74cbd992a298f67efb928b5b3754615e1924`.

[SEM-001](../../semiotics/sem-001-signs-in-governance/) utilisait les signes pour examiner les documents de gouvernance. Ici, un **signifiant** est la chaîne saisie par un musicien, comme `Cmi7` ; l'analyseur produit une **interprétation** structurée dans un arbre syntaxique abstrait (AST) ; et le générateur émet un symbole écrit privilégié. C'est une description informatique du comportement du code, pas une preuve de ce qu'un musicien entend ou veut exprimer. L'orthographe peut compter dans une tonalité ou une partition même lorsqu'un calcul machine regroupe les notes par classe de hauteurs. Traitez cela comme des affirmations distinctes nécessitant des preuves distinctes.

## 1. Texte saisi et texte canonique

Le service définit `Normalize` comme `Parse` suivi de `Render` si l'analyse réussit. L'analyseur accepte plusieurs signes pour la qualité mineure, dont `min`, `mi` et `-` ; le générateur écrit cette qualité `m`. Les [cas de test de normalisation](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs) figés comprennent `Cmi7 → Cm7` et `D-7 → Dm7`. La source explique pourquoi : fondamentale et composants sont conservés dans un AST, tandis que les caractères particuliers exprimant la qualité mineure sont remplacés selon la convention du générateur.

Il s'agit d'une transformation plusieurs-vers-un au niveau du texte. À partir du seul résultat `Cm7`, on ne peut retrouver si l'utilisateur avait saisi `Cmi7` ou `Cm7`. Elle est utile pour la recherche, la déduplication et un affichage cohérent, à condition que l'écran indique qu'il montre un symbole canonique. Si la notation exacte de l'utilisateur compte pour l'édition ou la provenance, conservez-la dans un champ distinct de texte saisi. Une valeur canonique ne devrait pas écraser silencieusement l'unique exemplaire du texte saisi.

Les preuves sont ici une **déclaration** de test versionnée et l'implémentation. Cette leçon n'a pas relancé la suite de tests. Les cas nommés sont vérifiables dans la source des tests, mais ne prouvent ni que toute notation utilisée par un guitariste est analysable, ni qu'une interface appelle ce service, ni que la chaîne rendue exprime toute intention harmonique.

### Exercice 1 — Suivre deux graphies

Quelles chaînes canoniques les tests figés attendent-ils pour `Cmi7` et `D-7` ? Quelle partie de chaque signe écrit change et que perdrait-on si GA ne stockait que la sortie canonique ?

> **Réponse :** Les sorties attendues sont `Cm7` et `Dm7`. Les marqueurs mineurs saisis `mi` et `-` deviennent `m` ; les lettres fondamentales et `7` restent. Si seule la sortie est stockée, l'orthographe originale du marqueur mineur ne peut être reconstruite.

## 2. Un symbole est composé de champs d'analyse

Un symbole d'accord n'est pas analysé comme une étiquette indivisible. Le [type AST](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/ChordAst.fs) possède `Root`, `RootAccidental`, une `Quality` facultative, une liste de `Components` et un `Bass` facultatif. L'analyseur essaie une lettre de note initiale, une altération facultative, une qualité facultative, zéro ou plusieurs extensions ou altérations, puis une basse après barre oblique facultative. Le générateur écrit ensuite chaque champ dans un ordre fixe. Cette séparation permet à un outil de déterminer ce qu'un jeton désigne dans l'implémentation plutôt que de deviner d'après la seule typographie.

Pour `EbΔ9`, le bémol appartient à la fondamentale `E`, `Δ` sélectionne la qualité `Major`, et `9` est une extension. Le générateur écrit la fondamentale `Eb`, la qualité majeure `maj` et l'extension `9`, donnant `Ebmaj9`. Cette paire exacte d'entrée et de sortie figure aussi dans les tests figés. Le signe `Δ` relève d'une convention de la grammaire acceptée par le DSL ; sa conversion en `maj` est un choix de rendu. Elle ne précise ni le voicing, ni la tonalité environnante, ni l'articulation de l'interprète. Une interface pourrait afficher « saisi : EbΔ9 » et « canonique : Ebmaj9 » pour préserver la distinction.

L'ordre de l'analyseur compte. Il teste certaines extensions de plusieurs caractères avant les composants courts. Cela empêche de décomposer `13` en `1` et `3`, et son commentaire précise que `maj7` doit être consommé comme extension entière plutôt que comme qualité `maj` seule suivie de `7`. Ce sont des règles de segmentation du code. Il ne faut pas en faire des affirmations sur une norme universelle de notation d'accords ; un autre système pourrait segmenter différemment la même forme écrite.

### Exercice 2 — Expliquer une substitution de glyphe

Avec l'analyseur, le générateur et le cas de test figés, quels champs expliquent `EbΔ9 → Ebmaj9` ? Le test établit-il un doigté de guitare particulier ?

> **Réponse :** La fondamentale `E` avec un bémol produit `Eb` ; `Δ` donne la qualité `Major` ; `9` est une extension. Le générateur produit `Ebmaj9`. Aucun doigté n'est encodé dans cette assertion d'entrée-sortie ; le test n'établit donc ni voicing ni interprétation sonore.

## 3. Ne pas confondre un champ AST avec le mot affiché

`Fmaj7/A` piège utilement le lecteur qui s'attend à trouver `Major` dans le champ `Quality` de l'AST. Dans l'analyseur figé, `maj` seul est bloqué lorsqu'il est suivi d'un chiffre ; `maj7` est alors consommé comme jeton complet `Extension "maj7"`. L'AST déduit de la source pour cette entrée possède donc la fondamentale `F`, aucune qualité explicite (`Quality=None`), une extension `maj7` et la basse `A`. Le générateur écrit la fondamentale `F`, aucun marqueur de qualité séparé, le composant `maj7` et la basse `/A`, donnant `Fmaj7/A`. Les tests de normalisation figés donnent cette sortie.

Cela ne signifie **pas** qu'un musicien qualifierait cet accord de « sans qualité ». Cela signifie que l'implémentation stocke le marqueur `maj7` sous `Components` plutôt que sous `Quality` pour cette analyse. Traiter les noms des champs internes comme une théorie complète du sens musical confondrait représentation informatique et objet représenté. Une vue diagnostique peut afficher « champ de qualité analysée : aucun » tandis qu'une vue destinée aux musiciens montre le symbole canonique. Le champ de basse consigne une notation avec barre oblique, pas une basse mesurée dans une prise particulière.

La même distinction affecte les explications générées. Si un assistant voit `Quality=None`, il ne devrait pas dire avec assurance à l'apprenant « il n'y a aucune qualité majeure ici » sans considérer le composant `maj7`. Une bonne explication peut citer les deux champs et le rendu canonique. La sémiotique devient ici un outil de qualité produit : la structure interne des signes du programme est utile, mais ses libellés doivent être interprétés avant d'atteindre le musicien.

### Exercice 3 — Examiner une analyse peu évidente

Pour `Fmaj7/A`, identifiez la fondamentale, le champ `Quality`, le composant, la basse et la sortie canonique déduits de la source. Pourquoi « aucune implication majeure » ne découle-t-il pas du seul `Quality=None` ?

> **Réponse :** Fondamentale `F` ; `Quality=None` ; composant `Extension "maj7"` ; basse `A` ; sortie canonique `Fmaj7/A`. L'analyseur représente `maj7` comme un composant ; le seul champ de qualité vide ne décrit donc pas le symbole complet.

## 4. Limites des jetons et altérations structurées

Le test figé de `C13#11b9` vérifie que l'analyse réussit, que la fondamentale vaut `C` et que l'AST contient **trois** composants. L'analyseur explique la décomposition attendue : `13` est une extension, `#11` une altération et `b9` une autre altération. C'est une interprétation de cette chaîne exacte déduite de la source ; le test affirme le nombre, mais pas indépendamment les trois noms de composants. Distinguer ces deux types de preuves rend l'exercice reproductible sans exagérer la couverture du test.

Les caractères `#` et `b` modifient ici des degrés numérotés du symbole ; ce ne sont pas l'altération de la fondamentale. L'analyseur traite une altération de fondamentale facultative immédiatement après la lettre, puis lit les composants suivants. Un système disant seulement « contient un dièse et un bémol » effacerait cette syntaxe et risquerait d'induire le lecteur en erreur. Un affichage structuré pourrait dire « fondamentale do ; extension 13 ; degré 11 avec dièse ; degré 9 avec bémol », tout en conservant `C13#11b9` pour comparaison.

Cet exemple n'établit ni voicing réel, ni inventaire des notes sur un instrument précis, ni préférence de notation d'un guitariste donné. Il montre la décomposition de l'analyseur et la structure de l'assertion versionnée. Une véritable vérification d'exécution appellerait le build figé avec cette entrée et comparerait l'AST ; une affirmation d'écoute nécessiterait une interprétation enregistrée distincte.

### Exercice 4 — Compter précisément les composants

Combien de composants le test figé `C13#11b9` exige-t-il ? Nommez les catégories déduites de la source et expliquez pourquoi la fondamentale reste `C`.

> **Réponse :** Le test exige trois composants. Les alternatives de l'analyseur donnent `Extension "13"`, `Alteration(Sharp, "11")` et `Alteration(Flat, "9")`. La fondamentale est `C`, car l'analyseur de fondamentale consomme la première lettre et aucune altération ne la suit immédiatement ; les `#` et `b` ultérieurs appartiennent aux composants.

## 5. Une projection constitue une autre affirmation que l'orthographe

La [closure `domain.projectChord`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L424-L486) figée accepte un `symbol` et les `fields` demandés. Entre autres champs, elle peut produire `root` à partir de la lettre et de l'altération analysées et `pc` à partir d'un calcul de demi-tons modulo douze. Dans la correspondance des notes de la source, do vaut zéro, ré deux, le dièse ajoute un et le bémol retranche un. La source prédit donc `root=C#`, `pc=1` pour `C#`, et `root=Db`, `pc=1` pour `Db`. Ce sont des résultats déduits pour cette paire d'entrées fixe, **pas** un résultat d'exécution de closure dans cette leçon.

Les deux chaînes de fondamentales diffèrent, tandis que leurs numéros de classes de hauteurs projetés coïncident. Les projeter sur `1` supprime volontairement l'orthographe. C'est utile pour une comparaison chromatique, mais n'autorise pas à remplacer la fondamentale saisie dans une partition ou à affirmer une fonction harmonique identique. Do dièse et ré bémol peuvent avoir des implications d'écriture différentes selon le contexte. Ni `root` ni `pc` seuls ne donnent la tonalité, l'intention du guitariste, l'accordage ou l'octave d'une note entendue. Une interface utile nomme les valeurs « symbole saisi », « symbole canonique », « fondamentale analysée » et « classe de hauteurs de la fondamentale » afin qu'une égalité de champ ne passe pas pour une égalité universelle.

L'analyseur se termine par `run pChord` sans exigence explicite de fin d'entrée. C'est une raison fondée sur la source de tester le traitement du texte final avant d'annoncer une validation stricte de la chaîne entière. Cette leçon ne prétend pas qu'un exemple mal formé soit accepté ou rejeté à l'exécution. Elle ne déduit pas non plus qu'un écran GA précis affiche actuellement les champs projetés de la closure. La recommandation produit consiste à montrer clairement la provenance lorsqu'un écran les utilise.

### Exercice 5 — Comparer signes et projection numérique

Pour les entrées `C#` et `Db`, prédisez `root` et `pc` d'après la source figée de `domain.projectChord`. Quelle égalité est établie et quelle conclusion plus forte exigerait un contexte musical ?

> **Réponse :** La source prédit `C#` : `root=C#`, `pc=1` ; `Db` : `root=Db`, `pc=1`. Leurs projections en classes de hauteurs de fondamentales sont égales, mais leurs orthographes diffèrent. Une même `pc` ne prouve ni notation, ni fonction tonale, ni voicing, ni interprétation entendue identiques.

## Limites et prochaine vérification

Cette leçon lit une implémentation figée et des tests versionnés ; elle n'affirme ni nouvelle exécution des tests, ni observation d'interface active, ni étude d'écoute. Les tests couvrent des exemples nommés, pas toutes les graphies. L'absence de contrôle explicite de fin d'entrée invite à un test de limite dédié ; ce n'est pas un résultat d'exécution mesuré. Les libellés d'interface proposés sont une application de conception, pas une affirmation sur le produit actuel. Une future validation devrait exécuter les cas nommés sur un build figé, examiner un vrai chemin d'appel d'interface et demander à des apprenants s'ils distinguent les valeurs saisies, canoniques, analysées et projetées. Révision humaine disciplinaire, essais d'apprenants et publication restent en attente ; ce brouillon français attend une révision par une personne maîtrisant le français.
