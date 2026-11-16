---
module_id: cog-002-feedback-integrity-fretboard-recall
department: cognitive-science
course: "Fiabilité du retour pour le rappel des notes sur le manche"
level: early-intermediate
prerequisites: [gtr-001-the-fretboard-map]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: cognitive-science-2026-10-11-002
version: "0.1.0"
---

# Fiabilité du retour pour le rappel des notes sur le manche

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](../../../../code/streeling/evidence/voicing-learning-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département des sciences cognitives** | Niveau : début intermédiaire | Durée estimée : 35 minutes | Statut : brouillon français ; révisions du contenu et de la traduction, essais auprès d'apprenants et publication en attente

## Objectifs

Après cette leçon, vous saurez :

- Vérifier une réponse affichée sur le manche à partir d'un ordre des cordes, d'un accordage et d'un calcul de frette déclarés.
- Distinguer un indice visible, la prédiction d'un apprenant, une réponse vérifiée et une tentative ultérieure dans un relevé de pratique.
- Expliquer précisément ce qu'affiche le manche SVG de GA à la révision fixée et ce que sa fonction de rappel au clic enregistre.
- Repérer une grille de réponses erronée sans transformer une observation du code source en affirmation non étayée sur les résultats d'apprentissage.

## La question du projet

Un guitariste qui consulte la démo du manche SVG de GA voit un ensemble de positions présenté comme un accord de C majeur. Les étiquettes de notes affichées pourraient-elles servir de grille de réponses à un exercice **prédire la note, puis vérifier** ? C'est un problème pratique de sciences cognitives : un retour ne peut corriger une prédiction que si sa grille de réponses est fiable. Si cette grille est fausse, une bonne réponse de l'apprenant peut être jugée erronée, tandis qu'une mauvaise réponse peut sembler correcte. C'est un risque à examiner, sans preuve qu'un utilisateur particulier ait déjà appris la mauvaise note.

Utilisez une seule révision du code source dans toute cette leçon : le commit GA [`dc2e74cbd992a298f67efb928b5b3754615e1924`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924). Les [six objets de position de la page de démonstration](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/pages/GuitarFretboardTest.tsx#L5-L13) constituent le jeu de données de l'exercice. Le [type et l'accordage par défaut du composant SVG](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/GuitarFretboard.tsx#L4-L85) définissent la lecture de ces positions. La page est explicitement une **page de test de l'ancien composant SVG** ; son nom ne prouve ni l'existence d'un test automatisé ni celle d'un parcours pédagogique déployé.

[COG-001](cog-001-your-brain-lies-to-you.fr.md) présente les biais cognitifs généraux. [GTR-001](../../guitar-studies/en/gtr-001-the-fretboard-map.md) enseigne la carte du manche. Ici, la tâche est plus précise : rendre une consigne de pratique particulière de GA vérifiable et définir ce qu'une réponse observée d'apprenant devrait contenir. Les sources fixées ne présentent aucune expérience sur la mémoire ou l'amélioration des compétences. L'idée qu'une prédiction sans aide suivie d'un retour vérifié puisse faciliter cette tâche reste une hypothèse pédagogique tant qu'elle n'a pas été testée auprès d'apprenants.

## 1. Fixer l'orientation avant de vérifier la grille

Le composant indique que `string: 0` désigne la corde **E aiguë** et utilise des indices de corde commençant à zéro, `0–5`. Son tableau d'accordage par défaut est `['E', 'B', 'G', 'D', 'A', 'E']`, explicitement de l'aigu au grave. Il diffère de la liste couramment récitée « E A D G B E », qui va du grave à l'aigu ; inverser l'ordre tout en conservant le même indice de corde produit des réponses assurées, mais fausses. La démo fournit six cordes et conserve l'accordage par défaut.

Pour ce jeu de données fixe en accordage standard, avancez d'un demi-ton par frette. On peut aussi attribuer les classes de hauteur `C=0, C#=1, ..., B=11`, ajouter le numéro de frette à la classe de hauteur de la corde à vide, puis réduire modulo 12. Écrivez la classe obtenue sous forme de nom de note. Par exemple, le E grave vaut `E=4` ; à la frette 3, `(4+3) mod 12 = 7`, soit **G**. Ce calcul vérifie l'étiquette d'une position ; il ne nous dit pas si l'ensemble de la forme d'accord est confortable, correctement doigté ou audible.

| Indice de corde | Corde à vide | Frette | Note calculée | Étiquette de la démo | Concordance ? |
|---:|---|---:|---|---|---|
| 0 | E aigu | 0 | E | E | oui |
| 1 | B | 1 | C | C | oui |
| 2 | G | 0 | G | G | oui |
| 3 | D | 2 | E | E | oui |
| 4 | A | 3 | C | C | oui |
| 5 | E grave | 3 | **G** | **C** | **non** |

Cinq des six étiquettes affichées concordent avec les notes calculées. La sixième position reste une **note de l'accord** de C majeur, puisque G appartient à la triade C–E–G. Le défaut est plus précis : l'étiquette de cette note individuelle est fausse. La démo attribue aussi à cette position `emphasized: true` et la même couleur rouge qu'aux autres positions étiquetées C. Puisque la documentation du composant décrit `emphasized` comme une mise en valeur facultative, par exemple celle d'une fondamentale, cet indice visuel pourrait renforcer la mauvaise étiquette dans une tâche de recherche de la fondamentale. Le code source n'établit pas comment un utilisateur interprète cette couleur.

### Exercice pratique 1 : lire le système de coordonnées

La démo contient `{ string: 5, fret: 3, label: 'C' }`. Quelle corde à vide l'indice 5 désigne-t-il, et quelle note la frette donne-t-elle avec l'accordage par défaut du composant ? Montrez le calcul de classe de hauteur.

> **Réponse :** L'indice 5 désigne le E grave, car le tableau va du E aigu à l'indice 0 au E grave à l'indice 5. La classe de hauteur de E vaut 4 ; `4 + 3 = 7`, et la classe 7 correspond à G. La note calculée est G : le C affiché est donc incohérent avec cet accordage et cette frette fixes.

### Exercice pratique 2 : examiner les six réponses

Donnez les notes calculées dans l'ordre du tableau de la démo, comptez les étiquettes concordantes et dites si l'étiquette erronée suffit à réfuter le nom « positions d'accord de C majeur ».

> **Réponse :** La séquence calculée est `E, C, G, E, C, G` ; la séquence affichée est `E, C, G, E, C, C`, soit cinq étiquettes concordantes sur six. G est une note de la triade de C majeur : ce calcul ne réfute donc pas l'ensemble de notes de l'accord. Il repère une **étiquette de marqueur** incorrecte, à la corde 5, frette 3.

## 2. Distinguer la question du retour

Le composant possède trois types d'indices textuels. `showFretNumbers` commande les numéros de frettes affichés en bas. `showStringLabels` commande les six étiquettes d'accordage des cordes à vide. Le champ facultatif `label` de chaque objet de position commande le texte à l'intérieur de son marqueur ; la [branche de rendu vérifie `pos.label`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/GuitarFretboard.tsx#L239-L318). Masquer les étiquettes de corde ne masque **pas** les noms de notes à l'intérieur des marqueurs de position renseignés. Inversement, laisser visibles les étiquettes de frettes et de cordes n'impose pas une étiquette de note à l'intérieur d'un marqueur.

Pour une tâche de prédiction proposée, un concepteur pourrait afficher un ensemble fixe de coordonnées de marqueurs sans leurs champs facultatifs `label`, demander à l'apprenant de nommer une note, puis afficher séparément une réponse vérifiée. Cela décrit **deux états préparés**, et non une fonction de révélation déjà mise en œuvre. La page de test à la révision fixée fournit immédiatement les étiquettes ; elle n'offre ni saisie de réponse, ni vérification de justesse, ni commande de révélation différée, ni historique d'apprenant. Cette limite compte : la lecture du code actuel ne permet pas d'établir le comportement de personnes dans un parcours qui n'existe pas encore.

Une grille de réponses fiable doit être déduite des mêmes coordonnées et du même accordage déclarés que la question, puis vérifiée indépendamment. Ne recopiez pas le sixième `label` de la démo à la fois dans la question et dans le validateur : la duplication de l'erreur rendrait une leçon défaillante cohérente en apparence. Un relevé minimal pour une étude réelle comprendrait la révision fixée du code source, la corde et la frette, l'accordage, l'état des indices visibles, la réponse de l'apprenant avant le retour, la grille vérifiée, le moment d'apparition du retour et toute réponse ultérieure. Sans ces champs, « l'utilisateur a cliqué sur G » ne constitue pas une trace de rappel en mémoire.

### Exercice pratique 3 : identifier l'indice visible

Supposons qu'un rendu fixe `showStringLabels: false` et `showFretNumbers: true`, mais transmet les six objets de position d'origine sans les modifier. Quels textes disparaissent, et le `C` erroné dans le sixième marqueur est-il masqué ?

> **Réponse :** Les six étiquettes d'accordage des cordes à vide disparaissent ; les numéros de frettes restent visibles. Chaque `label` de position fourni s'affiche toujours dans son marqueur : le sixième `C` erroné reste donc visible. Un état de prédiction avant la réponse devrait omettre les étiquettes de position ou les retenir d'une autre manière ; la page existante ne propose pas de commande de révélation testée.

## 3. Ce qu'une interaction peut mesurer, et ses limites

Le gestionnaire [`handlePositionClick`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/GuitarFretboard.tsx#L154-L157) du composant crée un nouvel objet contenant `{ string, fret }` et le transmet à la fonction de rappel facultative `onPositionClick`. Les cercles des marqueurs appellent ce gestionnaire lorsqu'on clique dessus. La fonction de rappel ne reçoit ni le `label` de la position d'origine, ni une proposition de note saisie, ni la justesse, ni l'heure du retour. Un clic peut indiquer la coordonnée sélectionnée si un composant parent enregistre ce rappel ; il ne peut pas, à lui seul, révéler quelle note l'apprenant croyait y trouver.

Voici une trace de deux tentatives délibérément **synthétique** pour le même item. Ce n'est pas une séance observée d'un utilisateur GA : avant correction, un apprenant répond `C` pour la corde 5, frette 3 ; après l'affichage d'une réponse `G` vérifiée, il répond `G` lors d'une nouvelle tentative immédiate. Avec la grille corrigée, les scores de cet item sont `0/1`, puis `1/1`. La trace montre un changement de réponse dans le jeu de données. Elle n'établit ni un rappel sans aide le lendemain, ni un transfert à une autre frette, ni le bénéfice d'un type d'indice par rapport à un autre. Ces questions nécessitent un test adapté auprès d'apprenants, avec un délai et une comparaison déclarés, ainsi que de véritables réponses enregistrées.

### Exercice pratique 4 : examiner la preuve fournie par un clic

Si un composant parent écoute `onPositionClick` et reçoit `{ string: 5, fret: 3 }`, peut-il déterminer si l'apprenant avait prédit G ? Nommez deux observations manquantes.

> **Réponse :** Non. La fonction de rappel transmet uniquement la coordonnée sélectionnée. Il faudrait au minimum la note déclarée par l'apprenant **avant** le retour et une grille de réponses vérifiée liée à l'accordage actuel ; il faudrait aussi le moment de présentation des indices et du retour pour évaluer un parcours prédire-puis-vérifier. L'absence de `label` dans le rappel compte particulièrement, car l'étiquette de cette coordonnée dans la démo source est erronée.

### Exercice pratique 5 : limiter une affirmation d'apprentissage

À partir de la trace synthétique ci-dessus, calculez les deux scores de l'item avec la réponse vérifiée G. Quelle affirmation limitée est étayée, et quelle affirmation plus large ne l'est pas ?

> **Réponse :** La première réponse C vaut `0/1` ; la seconde réponse immédiate G vaut `1/1`. Le relevé synthétique étaye seulement le fait que la réponse du jeu de données a changé après la correction fournie et que son score immédiat s'est amélioré. Il ne peut pas montrer qu'un véritable utilisateur GA s'est amélioré, a retenu G plus tard ou a bénéficié d'une révélation différée ; aucune mesure de ce type auprès d'utilisateurs ne figure dans les artefacts fixés.

## Preuves du projet et prochaine vérification

Le constat dans le code source est précis : à la révision GA fixée, une des six étiquettes de notes affichées contredit l'ordre des cordes et l'accordage standard du composant. Un petit calcul indépendant des classes de hauteur des six entrées fixes a produit `E, C, G, E, C, G` et une concordance des étiquettes de `5/6`. Ce calcul n'a exécuté ni navigateur, ni test automatisé de l'interface, ni étude auprès d'apprenants. Le code source montre les propriétés disponibles et les branches de rendu ; il ne prouve pas que la page est déployée ou utilisée pour l'enseignement.

Avant d'utiliser cette démo comme retour, corrigez et testez la grille de réponses à la même révision que le composant affiché. Pour toute expérience proposée de prédiction suivie d'une vérification, testez les deux états visibles et enregistrez une véritable réponse recueillie avant le retour ; ces étapes sont nécessaires avant d'avancer des affirmations sur le rappel en mémoire. Ce cours reste un brouillon traduit de l'anglais. Il n'a fait l'objet ni d'une révision du contenu par un spécialiste, ni d'une tentative d'apprenant, ni d'une révision linguistique, ni d'une synchronisation ou d'un build Learn, ni d'une vérification de publication.

## Sources à révision fixée

- [GA `GuitarFretboardTest.tsx` au commit `dc2e74cbd992a298f67efb928b5b3754615e1924`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/pages/GuitarFretboardTest.tsx) : les six positions étiquetées de la démo et la configuration de la page.
- [GA `GuitarFretboard.tsx` au même commit](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/GuitarFretboard.tsx) : indices de corde, accordage par défaut, étiquettes facultatives, données transmises au clic et rendu SVG.
