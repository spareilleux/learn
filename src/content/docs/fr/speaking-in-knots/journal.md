---
title: Journal
description: 'Notes de progression datées du cours Parler en nœuds — le diaporama français et sa copie anglaise, une somme d''états en Python vérifiée contre chaque valeur qu''affirment les tests d''IX, six erreurs volontaires qu''elle détecte, le Knot Atlas qui imprime l''image miroir du trèfle, et des blocs à rejouer qui permettent à une personne ou à un agent de relancer chaque entrée et de la vérifier.'
sidebar:
  order: 99
---

:::note[Rejouer une entrée]
Chaque entrée datée se termine par des blocs **À rejouer** : où lancer, la commande exacte, son entrée, la sortie attendue, et la vérification qui tranche. Une personne ou un agent peut les relancer et dire si l'entrée tient toujours. Un bloc qui n'a pas été lancé sur la machine de l'auteur le dit.
:::

## Progression

- [x] Le diaporama français, *Parler en nœuds*, et sa copie anglaise, *Speaking in Knots*, 52 diapositives chacun
- [x] `check.sh` : la somme d'états contre les 19 valeurs qu'affirment les tests d'IX, les mots de tresse cités par les leçons, et la vérification par mutation
- [x] Leçon 1 : les mots de tresse et le polynôme de Jones
- [x] Traductions française et espagnole
- [ ] Un workflow de CI qui lance `check.sh` sous Windows, Linux et macOS
- [ ] Leçon 2 : le code de Gauss (attend que le code de Gauss d'IX soit poussé)
- [ ] Leçon 3 : ce qu'IX refuse, et pourquoi
- [ ] Leçon 4 : les nœuds marins en 3D (attend que la corde posée d'IX soit poussée)

## Expériences

Chaque hypothèse ci-dessous a été écrite avant la mesure, dans [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/preregistration.md), commité sans changement avec les résultats. Quand aucune n'a été écrite, la ligne le dit.

| Question | Hypothèse | Résultat | Verdict | Où |
|---|---|---|---|---|
| Une somme d'états calculée hors d'IX donne-t-elle chaque valeur qu'affirment les tests d'IX à `e8684cf` ? | Oui : chaque polynôme de Jones affirmé, écrit à l'identique dans le format texte d'IX, et les composantes et torsions affirmées. | 19 vérifications sur 19 s'accordent. L'hypothèse disait le script indépendant : il suit la construction de l'aide `state_sum` déjà présente dans les tests d'IX, donc l'accord montre que les valeurs se reproduisent hors d'IX, pas qu'elles ont été obtenues indépendamment. | Confirmée | [2026-10-05](#2026-10-05--les-deux-diaporamas-et-le-polynôme-de-jones-vérifié-de-trois-façons) · [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) |
| Le Knot Atlas imprime-t-il, pour le trèfle, le polynôme du `s1^3` d'IX ? | Non : il imprime le polynôme miroir, −q⁻⁴ + q⁻³ + q⁻¹. | 3_1 imprime `- q^{-4} + q^{-3} + q^{-1}`, le polynôme de `s1^-3`. L2a1 fait de même pour l'entrelacs de Hopf ; 4_1 et L6a4 correspondent exactement à IX. La raison que donnait l'hypothèse, que l'Atlas dessine le trèfle gauche, n'a pas été vérifiée à part. | Confirmée | [2026-10-05](#2026-10-05--les-deux-diaporamas-et-le-polynôme-de-jones-vérifié-de-trois-façons) |
| La première vérification détecte-t-elle des erreurs volontaires dans le script ? | Aucune écrite à l'avance. | 6 mutants sur 6 la font échouer ; chacun s'accorde encore avec IX sur 12 à 16 des 19 vérifications. | Pas de verdict : aucune hypothèse enregistrée | [2026-10-05](#2026-10-05--les-deux-diaporamas-et-le-polynôme-de-jones-vérifié-de-trois-façons) · [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py) |

## 2026-10-05 — Les deux diaporamas, et le polynôme de Jones vérifié de trois façons

**Les diaporamas.** Le diaporama français, *Parler en nœuds*, a été construit pendant qu'IX apprenait à lire, vérifier et dessiner des nœuds. La copie anglaise le suit diapositive par diapositive, à partir de sa version `1791174928-7d71` : un changement ultérieur du diaporama français n'est pas reporté tout seul. La mise en page a été comparée mécaniquement, diapositive par diapositive : les mêmes balises et les mêmes attributs, seuls le texte, le texte alternatif des images et les libellés de section différant, et chaque image pointe vers une copie gardée dans le diaporama anglais.

**Ce qui peut se vérifier.** Seuls les mots de tresse et le polynôme de Jones sont dans le code poussé d'IX, dans la [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366) au commit `e8684cf`. Son exécution de CI [37216487957](https://github.com/GuitarAlchemist/ix/actions/runs/37216487957) a réussi le job build-and-test sous Ubuntu et Windows, avec Rust stable et nightly. Le rapport de risque y échoue : ce contrôle échoue par défaut sur les pull requests qui touchent des chemins protégés, et la pull request attend une relecture humaine. Le reste de ce que montre le diaporama (code de Gauss, fichiers `.knot`, corde posée, boucle 3D) est sur des branches locales qui ne sont pas poussées, et cette entrée ne le vérifie pas.

**Une somme d'états contre les tests d'IX.** Avant d'écrire le moindre code, j'ai noté l'hypothèse dans [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/preregistration.md). Puis [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) a recalculé chaque valeur qu'affirment les tests d'IX : 19 sur 19 s'accordent. La préinscription dit le script indépendant et écrit d'après la définition des manuels. C'est exagéré : sa construction (un union-find sur le diagramme fermé, un nœud par niveau et par position) est celle de l'aide `state_sum` des propres tests d'IX, et ces tests la comparent déjà à l'évaluation Temperley–Lieb d'IX sur 150 mots. Ce que l'accord ajoute, c'est que les valeurs se vérifient sans Rust ni le dépôt d'IX. La vérification indépendante est la suivante.

**Le Knot Atlas.** La page du trèfle, 3_1, imprime le polynôme de `s1^-3`, comme le prédisait la seconde hypothèse, et celle de l'entrelacs de Hopf, L2a1, celui de `s1^-2`. Le nœud de huit (4_1) et les anneaux borroméens (L6a4), chacun sa propre image miroir, correspondent exactement aux polynômes d'IX. Une table et IX peuvent dessiner des images miroirs opposées sous le même nom ; la [leçon 1](../01-braid-words/) fait vérifier les deux au lecteur.

**Six mutants.** [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py) change une ligne du script à la fois et exige que la première vérification échoue. Les six la font échouer. Aucun ne casse tout : chaque mutant s'accorde encore avec IX sur 12 à 16 des 19 vérifications, c'est pourquoi la vérification compare les 19 plutôt que quelques-unes.

**À rejouer 1 : la vérification du cours.** Lancé sur la machine de l'auteur : Windows 11, Git Bash, Python 3.14.3.

- Où : la racine d'un clone de [spareilleux/learn](https://github.com/spareilleux/learn), au commit qui ajoute cette entrée ou plus tard.
- Entrée : aucune. Python 3, bibliothèque standard seulement ; `PYTHON=…` choisit un autre interpréteur.
- Commande :

  ```bash
  bash code/speaking-in-knots/check.sh
  ```

- Sortie attendue, la première ligne étant votre version de Python :

  ```text
  Python 3.14.3
  ok   oracle
  ok   unknot-s1-s2
  ok   hopf
  ok   hopf-mirror
  ok   trefoil
  ok   borromean
  ok   torus-3-3
  ok   plait-6
  ok   mutants
  ```

- Vérification : statut de sortie 0, et chaque ligne après la première commence par `ok`. Une ligne `FAIL` suit la différence entre la sortie et le fichier de `expected/`.

**À rejouer 2 : les propres tests d'IX au commit épinglé.** Pas lancé sur la machine de l'auteur ; lancé par la CI d'IX.

- Où : un clone de [GuitarAlchemist/ix](https://github.com/GuitarAlchemist/ix), avec une chaîne d'outils Rust.
- Entrée : aucune.
- Commande :

  ```bash
  git fetch origin pull/366/head
  git checkout e8684cf
  cargo test -p ix-knot
  ```

- Sortie attendue : parmi les tests réussis, `jones::tests::known_knots_and_links`, `jones::tests::the_reef_knot_is_symmetric_and_the_granny_is_not` et `jones::tests::the_algebra_agrees_with_the_state_sum_and_the_markov_moves`, puis `test result: ok`. Le nombre de tests n'est pas noté ici.
- Vérification : statut de sortie 0. Pour comparer, l'exécution de CI 37216487957 a lancé `cargo test --workspace` et a réussi.

**À rejouer 3 : le Knot Atlas.** Lancé sur la machine de l'auteur le 2026-10-05 ; il faut le réseau.

- Où : n'importe où, avec `bash`, `curl` et `grep`.
- Entrée : les quatre pages 3_1, L2a1, 4_1 et L6a4 de [katlas.org](https://katlas.org/).
- Commande :

  ```bash
  for k in 3_1 L2a1 4_1 L6a4; do
    printf '%s: ' "$k"
    curl -s -A "streeling-review/1.0" "https://katlas.org/wiki/$k" | grep -A3 'Jones polynomial' | grep -o 'displaystyle{.*}\[/math\]' | head -1
  done
  ```

- Sortie attendue :

  ```text
  3_1: displaystyle{ - q^{-4} + q^{-3} + q^{-1}  }[/math]
  L2a1: displaystyle{ -\frac{1}{\sqrt{q}}-\frac{1}{q^{5/2}} }[/math]
  4_1: displaystyle{ q^2+ q^{-2} -q- q^{-1} +1 }[/math]
  L6a4: displaystyle{ -q^3- q^{-3} +3 q^2+3 q^{-2} -2 q-2 q^{-1} +4 }[/math]
  ```

- Vérification : en lisant *q* comme *t*, 3_1 est la ligne `s1^-3` de la sortie `oracle` d'À rejouer 1 et L2a1 est `expected/hopf-mirror.txt` ; 4_1 est la ligne `s1 s2^-1 s1 s2^-1` et L6a4 la ligne `s1 s2^-1 s1 s2^-1 s1 s2^-1`. Une page de wiki peut changer : une sortie différente veut dire comparer à nouveau, pas qu'IX a tort.

## À vérifier

- À rejouer 2 sur la machine de l'auteur : le cours ne s'appuie que sur la CI d'IX pour cela.
- Si le Knot Atlas dessine le trèfle gauche sous 3_1, la raison que donnait la seconde hypothèse ; seul le polynôme a été comparé.
- La pull request #366 est encore ouverte : les liens vers IX pointent vers le commit `e8684cf`, et restent valides après une fusion, mais le code peut changer d'ici là.
- Les chiffres de la partie 3D du diaporama viennent de commits locaux d'IX qui ne sont pas poussés ; le cours ne les reproduit pas.

## Questions ouvertes

- La documentation d'IX devrait-elle dire quelle image miroir est chaque nœud nommé, pour que comparer à une table ne demande pas les deux ?
- Un workflow de CI devrait-il lancer `check.sh` sur trois OS, comme le font les workflows des autres cours ? En ajouter un touche `.github/`, que relit le propriétaire du dépôt.
