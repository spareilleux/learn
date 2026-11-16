---
module_id: "cyb-013-bound-observation-age-before-a-control-decision"
department: "cybernetics"
course: "Borner l’ancienneté d’une observation avant une décision de contrôle"
level: "intermediate"
prerequisites: ["cyb-004-observe-before-correcting-a-feedback-loop", "net-008-map-clock-domains-before-ordering-events"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Borner l’ancienneté d’une observation avant une décision de contrôle

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un tableau de bord affiche toujours une valeur rassurante pendant qu’un agent prépare une correction. Il peut montrer une valeur actuelle ou le dernier échantillon réussi. Le prérequis sur l’observation demande si la preuve existe ; celui sur les horloges vérifie les coordonnées temporelles. Ce cours ajoute une question quantitative : de combien la valeur a-t-elle pu changer depuis l’observation sous une borne de vitesse explicitement supposée ?

Le modèle tient la mesure pour exacte à son horodatage et autorise ensuite un changement dans les deux sens. Multiplier le temps écoulé par la vitesse absolue maximale donne un rayon autour de l’ancienne valeur. Il s’agit d’un intervalle atteignable sous une borne, sans prédiction ajustée ni intervalle de confiance. Ses extrémités sont des possibilités permises par les hypothèses et non des mesures actuelles.

Une décision de seuil doit examiner tout l’intervalle. Si sa borne supérieure dépasse la limite, l’ancien échantillon ne certifie pas la sûreté actuelle. Cela ne prouve pas une violation : une trajectoire constante reste possible. À l’inverse, un intervalle entièrement acceptable soutient le certificat déclaré uniquement tant que la borne de vitesse reste valable. L’assistant doit préserver cette asymétrie entre inconnu et dangereux.

Le dossier conservé distingue un résumé répété d’une nouvelle mesure. Servez-vous-en pour contester un rapport qui actualise la date du document sans actualiser l’observation sous-jacente. Une enveloppe composable pourrait porter les deux dates ; commencez par les distinguer manuellement. Le contrôle modifie la fraîcheur en gardant la valeur affichée. Un outil qui produit le même intervalle a perdu une information utile à la décision, sans démontrer sa robustesse.

Le bloc [BRUTAL](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs) épinglé actualise `gpuSmooth` uniquement dans la branche de requête réussie. Une requête échouée ne rafraîchit pas cette valeur dans le bloc inspecté. La source justifie donc de distinguer lecture d’une valeur conservée et nouvel échantillon ; elle ne fournit aucune borne de vitesse mesurée.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: cyb-004-observe-before-correcting-a-feedback-loop](../../cybernetics/en/cyb-004-observe-before-correcting-a-feedback-loop.md)

[Prérequis: net-008-map-clock-domains-before-ordering-events](../../network-science/en/net-008-map-clock-domains-before-ordering-events.md)

[Artefact conservé du projet](../../../../code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Lecture primaire: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Lecture primaire: GA 76efbffd5af82b46c3146957a6bd4504008eeb89](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs)

## Modèle fixé et contrôle

```json
{
  "values": {
    "now_seconds": 10,
    "observed_at_seconds": 6,
    "observed_value": 4,
    "max_change_per_second": 0.5,
    "upper_limit": 5
  },
  "formula": "age=now-observed_at; radius=max_change_per_second*age; possible current interval=[observed_value-radius,observed_value+radius]; safe iff interval upper<=upper_limit.",
  "expected": {
    "age_seconds": 4,
    "radius": 2,
    "interval": [
      2,
      6
    ],
    "safe_certified": false
  },
  "negative_control": {
    "values": {
      "now_seconds": 10,
      "observed_at_seconds": 9,
      "observed_value": 4,
      "max_change_per_second": 0.5,
      "upper_limit": 5
    },
    "expected": {
      "age_seconds": 1,
      "radius": 0.5,
      "interval": [
        3.5,
        4.5
      ],
      "safe_certified": true
    },
    "why": "Same displayed value with a younger timestamp gives a smaller worst-case interval."
  },
  "assumptions": [
    "Same monotonic clock; exact initial measurement.",
    "Absolute rate bound holds throughout the elapsed interval.",
    "Safe means at or below the authored upper limit."
  ],
  "limits": "Failure to certify is uncertainty, not observed violation. No rate bound or real sensor was measured."
}
```

### Exercice 1

Calculez l’âge et le rayon maximal du cas principal.

<details><summary>Réponse 1</summary>

L’âge vaut `4` secondes et le rayon `2` unités de valeur. La vitesse est en unités de valeur par seconde ; son produit par le temps donne une borne de déplacement compatible, sans nouvelle mesure.

</details>

### Exercice 2

Quel intervalle actuel en résulte ? Peut-on certifier la sûreté ?

<details><summary>Réponse 2</summary>

L’intervalle vaut `[2,6]`. Sa borne supérieure dépasse `5`, donc `safe_certified=false`. L’échantillon ne fournit pas le certificat voulu sous la borne déclarée.

</details>

### Exercice 3

L’absence de certificat prouve-t-elle une violation actuelle ?

<details><summary>Réponse 3</summary>

Non. Le chemin constant à `4` et des chemins atteignant `6` sont tous permis. La sûreté actuelle reste indéterminée ; aucune violation observée ni commande d’action n’en découle.

</details>

### Exercice 4

Appliquez le contrôle avec une observation plus récente et comparez la décision.

<details><summary>Réponse 4</summary>

L’âge devient `1`, le rayon `0.5` et l’intervalle `[3.5,4.5]`. Donc `safe_certified=true`. Des valeurs affichées identiques peuvent soutenir des certificats différents selon leur ancienneté.

</details>

### Exercice 5

Quels champs faut-il garder dans un véritable essai de dogfooding ?

<details><summary>Réponse 5</summary>

Conservez l’identité et l’heure de l’observation, l’heure de lecture, la correspondance des horloges, les unités et la preuve de la borne de vitesse. Un résumé récent ne suffit pas. Aucun capteur réel, aucune validation de borne ni correction n’a été observé ici.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
