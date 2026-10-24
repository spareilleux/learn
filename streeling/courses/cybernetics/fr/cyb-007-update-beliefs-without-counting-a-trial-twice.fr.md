---
module_id: cyb-007-update-beliefs-without-counting-a-trial-twice
department: cybernetics
course: "Mettre à jour les croyances sans compter un essai deux fois"
level: intermediate
prerequisites: ["cyb-004-observe-before-correcting-a-feedback-loop", "fut-005-value-a-renderer-pilot-before-running-it"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Mettre à jour les croyances sans compter un essai deux fois

> **Portée du brouillon.** Traces de croyances et d'actions conçues pour le cours, probabilités conditionnelles exactes et lecture du code à une révision précise. Les revues humaines technique, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun contrôleur réel, essai de moteur de rendu ou canal de preuves étalonné n'ont été implémentés ou exécutés.

## La question du projet

Deux agents résument le même banc d'essai. Un contrôleur a-t-il reçu deux observations indépendantes ? Le [guide d'ingénierie agentique de GA](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/docs/methodology/agentic-engineering.md) recommande un travail délimité et une revue efficace. Cela motive la préservation des preuves au fil des transmissions ; ses recommandations ne fournissent pas un modèle d'indépendance probabiliste.

Utilisez la condition F/U stable conçue dans [FUT-005](../../futurology/en/fut-005-value-a-renderer-pilot-before-running-it.md), la loi a priori `1/2` et les vraisemblances positives de `4/5` en F et de `1/5` en U. La règle d'action choisit S seulement au-dessus de la probabilité a posteriori `3/5`, et K sinon. Nous distinguerons un nouvel essai d'une nouvelle enveloppe autour d'un ancien essai.

## 1. Mettre à jour avec un rapport de vraisemblance

La cote est `p/(1-p)`. La cote a priori vaut 1. Un résultat positif a pour rapport de vraisemblance `(4/5)/(1/5)=4` ; un résultat négatif a pour rapport `1/4`. Multiplier la cote a priori par le rapport approprié donne la cote a posteriori. La conversion inverse utilise `p=odds/(1+odds)`, conformément à la [formule de Bayes du NIST](https://www.itl.nist.gov/div898/handbook/apr/section2/apr1a.htm).

Après un résultat positif, la cote vaut 4 et la probabilité a posteriori `4/5`. Après un nouveau résultat négatif, la cote revient à 1 et la probabilité a posteriori à `1/2`. Cette multiplication suppose que les résultats des nouveaux essais sont indépendants conditionnellement au même état latent. L'indépendance est une propriété du modèle d'observation déclaré, et non du fait que deux messages sont arrivés.

### Exercice 1 : suivre de nouvelles observations

À partir de la loi a priori `1/2`, calculez les cotes et probabilités a posteriori après un résultat positif, puis un résultat négatif indépendant. Quelles actions découlent du seuil déclaré ?

> **Réponse:** La cote devient 4 et la probabilité a posteriori `4/5`, ce qui sélectionne S. Le résultat négatif indépendant multiplie la cote par `1/4`, la ramenant à 1 et la probabilité a posteriori à `1/2`, ce qui sélectionne K. Ces résultats exigent les hypothèses déclarées d'indépendance conditionnelle et d'état stable.

## 2. Reconnaître la copie d'un événement unique

Si le deuxième message est une copie déterministe du résultat positif du premier essai, il est positif avec une probabilité de 1 sachant cet événement observé, quel que soit l'état latent. Son rapport de vraisemblance conditionnel supplémentaire vaut donc 1. Il ne multiplie pas à nouveau la cote par 4.

En revanche, deux nouveaux essais positifs indépendants posés par le modèle donnent une cote de 16 et une probabilité a posteriori de `16/17`. La distinction porte sur l'observation sous-jacente, et non sur le ton assuré du résumé. Un nouvel identifiant d'enveloppe, un horodatage ou un texte différent ne créent pas un nouvel essai expérimental.

### Exercice 2 : comparer copie et répétition

Après un essai positif, comparez un rapport positif copié à un essai positif réellement nouveau et indépendant. Quelles probabilités a posteriori obtient-on ? Attribuer un nouvel identifiant de message au rapport copié règle-t-il la question ?

> **Réponse:** La copie laisse la probabilité a posteriori à `4/5` ; le nouveau résultat positif indépendant donne `16/17`. Un nouvel identifiant de message identifie l'enveloppe, et non une nouvelle observation conditionnellement indépendante. Préservez l'identité de l'essai sous-jacent et les hypothèses sur la production des nouveaux essais.

## 3. Observer le changement d'action lorsque les preuves sont dupliquées

Le [registre pédagogique](../../../../code/streeling/evidence/pilot-value-2026-10-22/belief-updates.json) contient trois messages :

| Enveloppe | Essai sous-jacent | Résultat | Probabilité a posteriori préservant l'identité | Probabilité a posteriori par décompte naïf des messages |
| --- | --- | --- | --- | --- |
| wrap-A | trial-A | positif | `4/5` | `4/5` |
| wrap-A-again | trial-A | positif copié | `4/5` | `16/17` |
| wrap-B | trial-B | négatif indépendant | `1/2` | `4/5` |

La trace correcte après le nouveau résultat négatif choisit K ; la trace naïve choisit S parce qu'elle a compté trial-A deux fois. C'est un contre-exemple dans un modèle d'observateur pédagogique, et non un bogue reproduit dans un contrôleur du projet en fonctionnement.

### Exercice 3 : situer la mise à jour injustifiée

Quel message ne doit pas ajouter un nouveau facteur de 4 ? Après wrap-B, donnez les deux probabilités a posteriori et les actions. Pourquoi le décompte des messages produit-il une décision différente ?

> **Réponse:** wrap-A-again répète trial-A et n'ajoute aucun facteur indépendant. Après wrap-B, la probabilité a posteriori préservant l'identité est `1/2`, ce qui choisit K, tandis que la probabilité naïve est `4/5`, ce qui choisit S. Son facteur supplémentaire de vraisemblance positive provenait d'une copie plutôt que d'un nouvel essai.

## 4. Distinguer identité, indépendance et comparabilité

Des essais réellement différents peuvent produire des résumés identiques octet par octet. Dédupliquer seulement selon l'empreinte d'un résumé pourrait effacer à tort une nouvelle information. Réciproquement, deux résumés différents peuvent décrire le même essai brut. Une transmission utile préserve la provenance de l'essai, la date de collecte, l'environnement, le protocole et les entrées communes, avec l'identité de l'artefact.

Même des essais distincts ne sont pas nécessairement conditionnellement indépendants ou comparables. Ils peuvent partager une perturbation, se chevaucher dans le temps, réutiliser un même résultat en cache ou observer un état qui a changé. Le [rapport historique BRUTAL M2](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m2-20261019-235218.md) et le [suivi M3](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) comportent des exécutions enregistrées distinctes et des contrôles variables, avec leur propre contexte de révision et de modifications non validées. Ils n'ont pas été générés par ce modèle binaire de vraisemblance.

### Exercice 4 : vérifier deux identités

Deux rapports ont des empreintes différentes mais citent le même essai. Deux autres ont des résumés identiques octet par octet mais proviennent de nouveaux essais distincts. L'égalité des empreintes doit-elle déterminer à elle seule les mises à jour des croyances ? Une identité d'essai distincte prouve-t-elle l'indépendance conditionnelle ?

> **Réponse:** Non. Des empreintes différentes peuvent envelopper un événement unique, tandis que des résumés égaux peuvent provenir d'événements distincts. Préservez la provenance de l'essai sous-jacent et le modèle de dépendance et de comparabilité. Une identité distincte permet d'examiner un nouvel essai, mais ne prouve pas à elle seule l'indépendance conditionnelle ou la stabilité de l'état latent.

## 5. Évaluer une nouvelle mise à jour avant de la demander

Après le premier résultat positif, un deuxième nouvel essai a une probabilité positive de `17/25` et négative de `8/25`. Le deuxième résultat positif donne une probabilité a posteriori de `16/17` et une perte optimale de `10/17` ; le négatif ramène la probabilité a posteriori à `1/2` et la perte à 4. La moyenne donne une perte attendue de `42/25=1.68`, contre une perte actuelle de 2. Sa valeur conditionnelle brute est de `8/25=0.32` point.

Après un premier résultat négatif, chacun des deux résultats du deuxième essai sélectionne encore K ; la valeur décisionnelle brute du deuxième essai est donc de 0 dans cette branche. En moyenne avant le premier résultat, la valeur marginale du deuxième essai est de `4/25=0.16`. Pour un coût de 0.6, un deuxième essai n'est intéressant dans aucune des deux branches de ce modèle pédagogique. C'est un calcul d'arrêt délimité ; il n'installe pas de règle d'arrêt en production et ne tranche pas les obligations de validation.

### Exercice 5 : décider de demander ou non un nouvel essai

Après un premier résultat positif, comparez la valeur brute de 0.32 du deuxième essai à son coût de 0.6. Quelle est sa valeur nette ? Que se passe-t-il après un premier résultat négatif, et ce modèle peut-il annuler une validation technique obligatoire ?

> **Réponse:** Après un résultat positif, la valeur nette est de `0.32-0.6=-0.28` point ; après un négatif, elle est de `0-0.6=-0.6`. Ne demandez pas le deuxième essai facultatif sous ces prémisses. La validation obligatoire est une obligation d'admissibilité distincte, et la vraisemblance, la persistance de l'état et le modèle de coût exigent encore une justification réelle avant de piloter un processus en fonctionnement.
