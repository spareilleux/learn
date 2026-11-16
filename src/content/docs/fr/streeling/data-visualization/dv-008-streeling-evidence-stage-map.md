---
title: Visualiser les sources, la relecture et la vérification publique de Streeling
description: Visualiser les sources, la relecture et la vérification publique de Streeling — Visualisation de données
sidebar:
  label: DV-008 · Visualiser les sources, la relecture et la vérification publique de Streeling
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/fr/dv-008-streeling-evidence-stage-map.fr.md
---

:::note[Streeling University]
**DV-008** · Visualiser les sources, la relecture et la vérification publique de Streeling · intermédiaire · 35 minutes

Généré par le département *Visualisation de données* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/fr/dv-008-streeling-evidence-stage-map.fr.md) · [Mon journal](../../journal/)

Prérequis: [DV-001](../../data-visualization/dv-001-observed-degraded-stale-quality/), [DV-002](../../data-visualization/dv-002-denominators-and-test-populations/)
:::

> **Département de visualisation des données** | Niveau : intermédiaire | Durée estimée : 35 minutes | Statut : brouillon de traduction ; relecture humaine du fond, relecture linguistique par une personne maîtrisant le français et essai par un apprenant en attente

Données pour les exercices hors ligne : [six instantanés GA figés](https://github.com/spareilleux/learn/blob/main/code/streeling/fixtures/data-visualization/historical-ga/README.md). Ces données sont historiques ; le comportement actuel du service n'est pas évalué.

## Objectifs

À la fin de ce cours, vous saurez :

- tracer des colonnes de preuves distinctes pour un cours rédigé, une relecture approuvée et une vérification publique anonyme ;
- préciser le dénominateur et la révision source de chaque nombre sans transformer une étape publique non mesurée en zéro ;
- montrer les cas où une page publique et une relecture existent, mais ne portent pas sur la même révision source ;
- reproduire une petite matrice synthétique de preuves et contester un graphique d'achèvement trompeur.

## La question du projet

L'objectif de Streeling est de disposer de 25 cours utiles au projet, relus et lisibles publiquement dans chacun des 21 départements proposant des cours : **525 codes distincts de cours du tronc commun**. Une personne chargée de la coordination demande : « Combien de cours sont terminés ? » Une seule barre de progression masquerait trois observations différentes. La source actuelle des cours se trouve dans Learn sous `streeling/` ; les observations historiques ci-dessous ont été recueillies lorsque Demerzel détenait cette source. Une relecture humaine doit approuver le contenu concerné, et Learn doit servir cette version relue de façon anonyme. Ce sont des affirmations distinctes, avec des preuves distinctes.

À la révision Demerzel épinglée [`8a37e1d`](https://github.com/GuitarAlchemist/Demerzel/tree/8a37e1d9a728a15ed384cbb912e3c8c518083d12/state/streeling), [`streeling_course_progress.py`](https://github.com/GuitarAlchemist/Demerzel/blob/8a37e1d9a728a15ed384cbb912e3c8c518083d12/scripts/streeling_course_progress.py) indique **120 codes de cours du tronc commun**, **121 fichiers sources anglais** et **zéro fiche de production marquée comme approuvée à la relecture**. Le fichier anglais supplémentaire est CYB-026, facultatif et hors des 25 premiers numéros du tronc commun. Le script examine l'état du dépôt ; il **n'interroge pas** le site public Learn et n'établit pas la qualité du contenu. Ces nombres décrivent cette révision, et non le catalogue d'aujourd'hui.

Le script distinct [`streeling_public_readback.py`](https://github.com/GuitarAlchemist/Demerzel/blob/8a37e1d9a728a15ed384cbb912e3c8c518083d12/scripts/streeling_public_readback.py) accepte un SHA Demerzel complet et des identifiants de modules. Il récupère anonymement l'index Streeling et les pages des modules, puis vérifie le statut HTTP 200, un lien source exact et le titre rendu. Son résultat ne couvre que les pages et la révision demandées ; il ne certifie ni la relecture humaine ni l'apprentissage. Comme le rapport de progression épinglé ne contient aucune vérification publique exhaustive, le **nombre public est inconnu** dans ce périmètre de preuves. Ne le représentez pas comme zéro.

### Exercice 1 : étiqueter la référence de départ

À la révision épinglée, le titre du graphique devrait-il être « 121 sur 525 terminés », « 120 sur 525 rédigés » ou « zéro cours publié » ? Donnez le titre le plus défendable et un sous-titre.

> **Réponse :** « 120 codes de cours du tronc commun sur 525 ont un brouillon source anglais à la révision Demerzel `8a37e1d`. » Le 121e fichier anglais est CYB-026, facultatif. Un sous-titre devrait préciser : « 0 approbation dans les fiches de production examinées à cette révision ; nombre public exact non mesuré par ce rapport. » Ni un fichier anglais ni une mesure publique absente ne prouvent l'achèvement.

## 1. Expliciter les colonnes de preuves

Utilisez une ligne par code de cours et trois colonnes alignées. **Source** signifie un fichier anglais portant un code distinct du tronc commun ; **relecture** signifie un verdict humain applicable à cette version exacte du cours ; **public** signifie une vérification anonyme réussie contre le même SHA source. Un booléen dans une fiche de production est un signal d'inventaire utile, mais il faut aussi examiner l'identité de la personne qui a relu, le verdict et le blob du contenu avant d'affirmer qu'une relecture humaine est valide. Un statut HTTP 200 seul dit uniquement qu'une page a répondu.

Les [fiches synthétiques](https://github.com/spareilleux/learn/blob/main/code/streeling/fixtures/data-visualization/dv-008/scenarios.json) locales et l'[évaluateur](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/scripts/streeling_fixtures/data-visualization/dv-008/analyze.py) permettent de s'exercer à cette disposition. Le lien de l'évaluateur épingle son implémentation archivée ; les trois fichiers de données locaux conservent ses données. Pour rejouer ce modèle historique à six fiches, utilisez un checkout Demerzel à la révision source archivée et lancez cette commande depuis sa racine :

```text
python -I -B scripts/streeling_fixtures/data-visualization/dv-008/analyze.py --check
```

Les six fiches sont des états inventés pour le cours, **et non des modules Streeling observés**. Toutes ont une source rédigée. Les fiches A et B ont une relecture approuvée. A et F ont une vérification publique exacte. Seule A satisfait les trois conditions. F a délibérément une provenance publique exacte sans relecture approuvée ; B a une approbation mais un statut public 404. C a un statut public 200 et un titre correspondant, mais des liens sources d'index et de module périmés. E a une source de module et un titre correspondants, tandis que l'index cite toujours une autre révision. Ces exceptions montrent pourquoi les colonnes doivent rester visibles. Un entonnoir seul suggérerait que chaque étape ultérieure est un sous-ensemble de toutes les précédentes ; les preuves ne le garantissent pas.

| Fiche | Source rédigée | Relecture approuvée | Public exact | Les trois |
|---|---|---|---|---|
| A | Oui | Oui | Oui | Oui |
| B | Oui | Oui | Non : 404 | Non |
| C | Oui | Non | Non : liens périmés | Non |
| D | Oui | Non | Non : 404 | Non |
| E | Oui | Non | Non : index périmé | Non |
| F | Oui | Non | Oui | Non |

### Exercice 2 : compter les fiches pédagogiques

Exécutez l'évaluateur. Donnez les quatre nombres : source rédigée, relecture approuvée, public exact et les trois. Quelle fiche réfute l'affirmation selon laquelle une provenance publique implique une relecture approuvée ?

> **Réponse :** Les nombres synthétiques sont **6, 2, 2 et 1**. F a une vérification publique exacte, mais aucune relecture approuvée. B montre l'inverse : l'approbation n'implique pas une page publique. Ces nombres sont des propriétés des fiches inventées, et non de six véritables cours Streeling.

## 2. Représenter fidèlement les états inconnus et périmés

Pour une révision source fixe, une grille utile utilise **oui**, **non** et **non mesuré**, avec des mots ou des symboles dans chaque cellule. La colonne publique exige une quatrième explication lorsqu'une page existe mais renvoie vers une source plus ancienne. Une réponse 200 avec le bon titre n'est pas une vérification de source exacte ; un aperçu généré dans un dossier local `dist/` n'est pas non plus une preuve de déploiement anonyme. Indiquez l'horodatage d'une vérification publique, car un résultat valide peut devenir périmé après le déploiement suivant. Cela suit [DV-001](../../data-visualization/dv-001-observed-degraded-stale-quality/) : les observations absentes et historiques ne sont pas des zéros actuels.

Pour l'instantané de progression épinglé, un affichage compact pourrait être :

```text
Core source drafts     120 / 525   observed at Demerzel 8a37e1d
Approved review         0 / 120   production-record signal at that revision
Exact public readback   ? / 120   not exhaustively measured by this report
All gates               ? / 525   cannot be certified from these inputs
```

Ce n'est **pas** un entonnoir de conversion unique. Un nombre de cours relus peut utiliser tous les modules rédigés comme dénominateur pour mesurer l'avancement des relectures, tandis que l'achèvement final utilise les 525 objectifs du tronc commun. Un passage public exhaustif, une comparaison de la source exacte et une validation des justificatifs pourraient établir plus tard les nombres restants. D'ici là, conservez les points d'interrogation. Dans un tableau de bord, montrez le SHA source pertinent, l'horodatage de la vérification, le code du cours et des liens directs vers les preuves dans un tableau accessible ; ne codez pas l'état par la seule couleur.

### Exercice 3 : corriger le graphique

Un tableau de bord de livraison affiche trois barres de même largeur étiquetées « Brouillons 120 ; Relus 0 ; Publiés 0 » et appelle cela « 120 cours terminés ». Relevez deux erreurs de preuve et remplacez son libellé public.

> **Réponse :** Les 120 sont des brouillons rédigés du tronc commun, et non des cours terminés, relus et publics. Le script de progression épinglé n'a pas mesuré toutes les pages publiques ; « Publiés 0 » invente donc un résultat. Utilisez « Vérification publique de source exacte : non mesurée pour l'ensemble ». De plus, des barres de même largeur masqueraient les nombres et les dénominateurs différents. Précisez la révision épinglée et montrez 0 comme signal de relecture dans les fiches de production, en attendant la validation des justificatifs.

## 3. Tester la jointure sur la source exacte et sa portée

Le script public exige que l'index renvoie vers `tree/<sha>/state/streeling/courses` et que chaque page de module renvoie vers `blob/<sha>/<course path>`, en plus d'un titre correspondant et d'un statut HTTP 200. Ses vérifications sont délibérément étroites : elles établissent la provenance d'une page anonyme et un titre rendu pour le SHA demandé. Elles ne comparent pas chaque paragraphe ou exercice à la source et n'examinent pas la relecture. Une relecture humaine liée à un autre blob de cours doit être réexaminée après des modifications. C'est une jointure sur une version exacte, et non un comptage de libellés favorables.

**Limite liée à la migration :** le script épinglé décrit l'ancien import de Demerzel vers Learn. Les pages Learn actuelles utilisent des liens source/édition vers Learn `main`, et la copie initiale et les manifestes supplémentaires ont des origines différentes. Une URL `main` mutable seule n'identifie pas la révision déployée du cours. L'ancien script n'a pas été adapté ni exécuté pour valider cette version candidate de Learn. Pour une vérification actuelle, liez le commit Learn déployé, le blob source relu, son origine supplémentaire le cas échéant et le contenu rendu du cours. Un échec du seul ancien motif de lien ne prouve pas qu'une page actuelle est incorrecte.

L'évaluateur pédagogique modélise les quatre booléens de la vérification publique, mais n'effectue aucune requête HTTP. Il utilise une petite matrice pour que le raisonnement soit reproductible sans accès réseau. Pour le pipeline archivé, le véritable script public pouvait s'exécuter une fois le SHA Demerzel commité, accessible et déployé. Pour le pipeline actuel, établissez d'abord une vérification contre la révision Learn déployée et le contenu relu ; cette vérification publique propre à la version candidate reste en attente. Examinez indépendamment l'identité source du justificatif de relecture. Ne copiez pas un résultat synthétique « A a réussi » dans une fiche de production.

### Exercice 4 : diagnostiquer une correspondance partielle

La fiche E renvoie HTTP 200, le lien source du module et le titre correspondent à la cible, mais le lien source de l'index ne correspond pas. Faut-il compter cette fiche dans la vérification publique de source exacte ? Nommez la prochaine vérification pour un véritable déploiement Streeling.

> **Réponse :** Non. Le contrat épinglé de vérification exige la provenance de l'index et du module. Pour le pipeline historique, examinez la source de l'index et la révision du générateur avant de déployer la copie Demerzel visée. Pour Learn actuel, examinez la révision Learn déployée, les provenances de la copie initiale et des ajouts, puis le cours rendu par rapport à la source relue ; répétez ensuite la vérification anonyme. Ne déduisez pas que le site entier est à la révision cible d'une seule page de module correspondante.

## 4. Rendre visible la prochaine action

La grille doit conduire au travail, pas simplement décorer un rapport. Pour un brouillon sans relecture, donnez à la personne chargée de relire le fond une tâche d'apprenant sans réponses et un dossier de relecture lié à la source. Pour un cours relu sans vérification publique de source exacte, contrôlez la synchronisation Learn et le déploiement. Pour une page publique exacte sans relecture, terminez la relecture avant de déclarer l'achèvement. Si un fichier source change après approbation, comparez son nouveau blob au blob relu et demandez un nouveau verdict lorsque le changement affecte le contenu relu. Ces actions découlent des preuves manquantes de chaque ligne, et non d'un « pourcentage terminé » générique.

Ne transformez pas `pipeline_review_approved` en verdict humain sans examiner le justificatif sous-jacent. N'assimilez pas un aperçu local Learn à une page publique. Enfin, rappelez-vous les termes « utile au projet » et « exercices vérifiables » de l'objectif : la carte en trois étapes est nécessaire à la rigueur de publication, mais elle ne prouve pas à elle seule que le cours est exact, utile à un utilisateur GA/IX/Demerzel/Learn ou réussi pour un apprenant.

### Exercice 5 : décider quoi rapporter

Supposons qu'un nouveau brouillon DV-008 passe les contrôles préalables locaux et que Learn puisse le rendre localement, mais qu'aucun humain ne l'ait relu et qu'aucune URL anonyme n'ait été testée. Rédigez un état en une phrase et deux prochaines actions produisant des preuves.

> **Réponse :** « DV-008 est un brouillon source anglais avec des éléments locaux de cohérence et d'aperçu ; la relecture humaine et la vérification publique de source exacte restent en attente. » Donnez à une personne chargée de la relecture la tâche sans réponses et le blob source exact pour obtenir un verdict consigné, puis générez et déployez la révision Learn relue et effectuez une vérification anonyme actuelle du cours, de l'index et du contenu rendu attendu. Un aperçu local n'est ni une relecture humaine ni une observation publique.

## À retenir

- Un brouillon source, une relecture approuvée et une page publique de source exacte répondent à des questions différentes.
- La provenance publique et l'approbation humaine peuvent survenir dans n'importe quel ordre ; comptez leur intersection pour l'achèvement.
- Zéro est un nombre observé ; inconnu signifie que la mesure pertinente n'a pas été effectuée.
- Épinglez le SHA source, le blob du cours, le justificatif de relecture et l'heure de vérification avant de combiner les preuves.
- Un graphique d'état reste une aide à la navigation ; la réussite des apprenants et l'utilité pour le projet nécessitent des tests séparés.

## Éléments du projet et limites

- Les scripts Demerzel épinglés [`streeling_course_progress.py`](https://github.com/GuitarAlchemist/Demerzel/blob/8a37e1d9a728a15ed384cbb912e3c8c518083d12/scripts/streeling_course_progress.py) et [`streeling_public_readback.py`](https://github.com/GuitarAlchemist/Demerzel/blob/8a37e1d9a728a15ed384cbb912e3c8c518083d12/scripts/streeling_public_readback.py) définissent les deux périmètres mesurés. Le nombre de progression a été reproduit à cette révision ; aucun passage public complet ne l'a été.
- Le [jeu de six fiches](https://github.com/spareilleux/learn/blob/main/code/streeling/fixtures/data-visualization/dv-008/scenarios.json) est synthétique. Ses résultats 6/2/2/1 n'estiment pas les taux réels de publication.
- Il s'agit d'un brouillon de traduction française d'un brouillon anglais ; les traductions FR/ES sont préparées séparément. Aucun verdict humain sur le fond, essai par un apprenant, relecture linguistique par une personne maîtrisant la langue, déploiement Learn ou vérification anonyme de DV-008 n'est revendiqué.

*Recherche : `data-visualization-2026-10-21-008`. Relecture et publication en attente.*
