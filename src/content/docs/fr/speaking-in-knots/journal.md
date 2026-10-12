---
title: Journal
description: 'Notes de progression datées du cours Parler en nœuds — le diaporama français et sa copie anglaise, une somme d''états en Python vérifiée contre les valeurs qu''affirment les tests d''IX, six erreurs volontaires qu''elle détecte, le Knot Atlas qui affiche l''image miroir du trèfle, ce qu''a trouvé une relecture indépendante, et des blocs à rejouer qui permettent à une personne ou à un agent de relancer chaque entrée et de la vérifier.'
sidebar:
  order: 99
---

:::note[Rejouer une entrée]
Chaque entrée datée se termine par des blocs **À rejouer** : où lancer, la commande exacte, son entrée, la sortie attendue, et la vérification qui tranche. Une personne ou un agent peut les relancer et dire si l'entrée tient toujours. Un bloc qui n'a pas été lancé sur la machine de l'auteur le dit.
:::

## Progression

- [x] Le diaporama français, *Parler en nœuds*, et sa copie anglaise, *Speaking in Knots*, 52 diapositives chacun
- [x] `check.sh` : la somme d'états contre les 26 valeurs qu'affirment les tests d'IX sur des mots d'au plus 6 croisements, les mots de tresse cités par les leçons, et la vérification par mutation
- [x] Leçon 1 : les mots de tresse et le polynôme de Jones
- [x] Traductions française et espagnole
- [x] Deux relectures indépendantes du cours contre le code source d'IX, et les constats bloquants qui portent sur le cours corrigés ; le dernier, partager le diaporama anglais, revient au propriétaire
- [ ] Un workflow de CI qui lance `check.sh` sous Windows, Linux et macOS
- [ ] Leçon 2 : le code de Gauss (attend que le code de Gauss d'IX soit poussé)
- [ ] Leçon 3 : ce qu'IX refuse, et pourquoi
- [ ] Leçon 4 : les nœuds marins en 3D (attend que la corde posée d'IX soit poussée)

## Expériences

Chaque hypothèse ci-dessous a été écrite avant la mesure, dans [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/preregistration.md). Elle a été enregistrée sans changement, dans le même commit que les résultats, si bien que l'historique ne peut pas montrer qu'elle est venue d'abord : cela repose sur la parole de l'auteur. Quand aucune hypothèse n'a été écrite, la ligne le dit.

| Question | Hypothèse | Résultat | Verdict | Où |
|---|---|---|---|---|
| Une somme d'états calculée hors d'IX donne-t-elle les valeurs qu'affirment les tests d'IX à `e8684cf` ? | Oui : chaque polynôme de Jones affirmé, écrit à l'identique dans le format texte d'IX, et les composantes et torsions affirmées. | 26 vérifications sur 26 s'accordent : chaque polynôme de Jones, nombre de composantes, torsion, permutation et symétrie qu'affirment les tests d'IX sur des mots d'au plus 6 croisements. La première exécution en vérifiait 19 et appelait cela chaque valeur ; la relecture du 2026-10-06 a trouvé les 7 autres. L'hypothèse disait aussi le script indépendant : il suit la construction de la fonction auxiliaire `state_sum` déjà présente dans les tests d'IX, donc l'accord montre que les valeurs se reproduisent hors d'IX, pas qu'elles ont été obtenues indépendamment. | Confirmée | [2026-10-05](#2026-10-05--les-deux-diaporamas-et-le-polynôme-de-jones-vérifié-de-trois-façons) · [2026-10-06](#2026-10-06--ce-qua-trouvé-une-relecture-indépendante) · [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) |
| Le Knot Atlas affiche-t-il, pour le trèfle, le polynôme du `s1^3` d'IX ? | Non : il affiche le polynôme miroir, −q⁻⁴ + q⁻³ + q⁻¹. | 3_1 affiche `- q^{-4} + q^{-3} + q^{-1}`, le polynôme de `s1^-3`. L2a1 fait de même pour l'entrelacs de Hopf ; 4_1 et L6a4 correspondent exactement à IX. La raison que donnait l'hypothèse, que l'Atlas dessine le trèfle gauche, n'a pas été vérifiée à part. | Confirmée | [2026-10-05](#2026-10-05--les-deux-diaporamas-et-le-polynôme-de-jones-vérifié-de-trois-façons) |
| La première vérification détecte-t-elle des erreurs volontaires dans le script ? | Aucune écrite à l'avance. | 6 mutants sur 6 la font échouer ; chacun s'accorde encore avec IX sur 16 à 23 des 26 vérifications. | Pas de verdict : aucune hypothèse enregistrée | [2026-10-05](#2026-10-05--les-deux-diaporamas-et-le-polynôme-de-jones-vérifié-de-trois-façons) · [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py) |

## 2026-10-05 — Les deux diaporamas, et le polynôme de Jones vérifié de trois façons

**Les diaporamas.** Le diaporama français, *Parler en nœuds*, a été construit pendant qu'IX apprenait à lire, vérifier et dessiner des nœuds. La copie anglaise le suit diapositive par diapositive, à partir de sa version `1791174928-7d71` : un changement ultérieur du diaporama français n'est pas reporté tout seul. La mise en page a été comparée mécaniquement, diapositive par diapositive : les mêmes balises et les mêmes attributs, seuls le texte, le texte alternatif des images et les libellés de section différant, et chaque image pointe vers une copie gardée dans le diaporama anglais.

**Ce qui peut se vérifier.** De ce que montre le diaporama, seuls les mots de tresse, le polynôme de Jones et une disposition 3D des brins sont dans le code poussé d'IX, dans la [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366) au commit `e8684cf`. Son exécution de CI [37216487957](https://github.com/GuitarAlchemist/ix/actions/runs/37216487957) a réussi le job build-and-test sous Ubuntu et Windows, avec Rust stable et nightly. Son rapport de risque échoue, et la pull request attend une relecture humaine. Le reste (code de Gauss, fichiers `.knot`, corde posée, boucle 3D) est sur des branches locales qui ne sont pas poussées, et cette entrée ne le vérifie pas.

**Une somme d'états contre les tests d'IX.** Avant d'écrire le moindre code, j'ai noté l'hypothèse dans [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/preregistration.md). Puis [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) a recalculé 19 valeurs qu'affirment les tests d'IX, et les 19 s'accordaient ; l'entrée suivante ajoute les 7 qui manquaient. Le préenregistrement dit le script indépendant et écrit d'après la définition des manuels. C'est exagéré : sa construction (un union-find sur le diagramme fermé, un nœud par niveau et par position) est celle de la fonction auxiliaire `state_sum` des propres tests d'IX, et ces tests la comparent déjà à l'évaluation Temperley–Lieb d'IX sur 150 mots. Ce que l'accord ajoute, c'est que les valeurs se vérifient sans Rust ni le dépôt d'IX. La vérification indépendante est la suivante.

**Le Knot Atlas.** La page du trèfle, 3_1, affiche le polynôme de `s1^-3`, comme le prédisait la seconde hypothèse, et celle de l'entrelacs de Hopf, L2a1, celui de `s1^-2`. Le nœud de huit (4_1) et les anneaux borroméens (L6a4), chacun sa propre image miroir, correspondent exactement aux polynômes d'IX. Une table et IX peuvent dessiner des images miroirs opposées sous le même nom ; la [leçon 1](../01-braid-words/) fait vérifier les deux au lecteur.

**Six mutants.** [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py) change une ligne du script à la fois et exige que la première vérification échoue. Les six la font échouer. Aucun ne casse tout : chaque mutant s'accorde encore avec IX sur la plupart des vérifications, c'est pourquoi la vérification les compare toutes plutôt que quelques-unes.

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

- Vérification : en lisant *q* comme *t*, 3_1 est la ligne `s1^-3` de `expected/oracle.txt` et L2a1 est `expected/hopf-mirror.txt` ; 4_1 est la ligne `s1 s2^-1 s1 s2^-1` et L6a4 la ligne `s1 s2^-1 s1 s2^-1 s1 s2^-1`. Une page de wiki peut changer : une sortie différente veut dire comparer à nouveau, pas qu'IX a tort.

## 2026-10-06 — Ce qu'a trouvé une relecture indépendante

Avant la fusion, un relecteur qui n'avait pas participé à l'écriture du cours a lu la pull request contre le code source d'IX à `e8684cf`. Il a signalé sept problèmes bloquants. Chacun a été vérifié contre le code source avant d'être corrigé :

- **Le sens de lecture était le sens miroir.** La leçon 1 disposait les brins de haut en bas. IX dispose une tresse avec *y* qui monte, et [`layout.rs`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/layout.rs#L26-L39) dit qu'une image où *y* descend montre la tresse miroir : un lecteur qui dessinait `s1^3` comme le disait la leçon obtenait le trèfle gauche, là où IX calcule le trèfle droit. La leçon lit désormais les tresses de bas en haut, et dit pourquoi.
- **« Chaque valeur qu'affirment les tests d'IX » faisait 19 valeurs.** Le script manquait la symétrie du nœud de huit, la torsion d'une tresse miroir, les trois identités du test du nœud plat et du nœud de vache, et la torsion et la permutation qu'affirment les tests de l'outil `ix_braid`. Il vérifie maintenant les 26, toujours en accord, et nomme les tests d'IX qu'il ne reproduit pas : celui à 63 et 64 croisements, hors de sa portée, et les 150 mots générés, qui vérifient des relations plutôt que des valeurs écrites.
- **Le code poussé d'IX a aussi une disposition 3D** des brins, `layout.rs`, que l'entrée précédente omettait.
- **Les commandes diffèrent entre Windows et les autres systèmes** (`python` contre `python3`) : la leçon est maintenant une page `.mdx` avec un onglet par système, comme le demande AGENTS.md.
- **Python et Rust** sont maintenant liés à leur première mention dans la leçon.
- **Linux et macOS n'ont jamais été lancés**, ce que dit maintenant *À vérifier*.
- **Le diaporama anglais était privé** quand la relecture l'a lu, alors que le français était déjà partagé avec toute personne disposant du lien. Le cours n'est pas fusionné avant que les deux le soient.

La relecture a aussi noté que le diaporama français a changé depuis la copie : version `1791213311-03e2` quand la relecture l'a lu le 2026-10-06, contre `1791174928-7d71` pour la source de la copie. La copie anglaise ne le suit pas.

**Une seconde relecture**, du cours corrigé, a confirmé cinq de ces corrections, trouvé le lien vers Python encore absent à sa première mention et le diaporama anglais encore privé, et trouvé un problème bloquant de plus. La leçon 1 expliquait la différence de l'entrelacs de Hopf avec le Knot Atlas par l'image miroir ; or, sans sens de parcours, deux anneaux accrochés sont leur propre image miroir : la différence vient du sens dans lequel un anneau est parcouru, qui change le signe des deux croisements. La leçon le dit maintenant, et garde l'accord exact pour les nœuds qui sont leur propre image miroir. La même relecture a trouvé que les 150 mots générés ne sont pas hors de portée du script (10 croisements au plus) : le script ne les reproduit pas parce qu'ils vérifient des relations, pas des valeurs écrites. Elle a aussi relevé de plus petits problèmes de formulation, corrigés.

**À rejouer 4 : les 26 vérifications.** Lancé sur la machine de l'auteur : Windows 11, Git Bash, Python 3.14.3.

- Où : la racine d'un clone de [spareilleux/learn](https://github.com/spareilleux/learn), au commit qui ajoute cette entrée ou plus tard.
- Entrée : aucune.
- Commande :

  ```bash
  bash code/speaking-in-knots/check.sh > /dev/null && tail -2 code/speaking-in-knots/out/oracle.txt
  ```

- Sortie attendue :

  ```text
  26/26 agree with IX at e8684cf
  exit 0
  ```

- Vérification : exactement ces deux lignes. `exit 0` est le statut du script lui-même, que `check.sh` ajoute à sa sortie.

## À vérifier

- `check.sh` sous Linux et macOS : il n'a été lancé que sous Windows 11.
- À rejouer 2 sur la machine de l'auteur : le cours ne s'appuie que sur la CI d'IX pour cela.
- Si le Knot Atlas dessine le trèfle gauche sous 3_1, la raison que donnait la seconde hypothèse ; seul le polynôme a été comparé.
- La pull request #366 est encore ouverte : les liens vers IX pointent vers le commit `e8684cf`, et restent valides après une fusion, mais le code peut changer d'ici là.
- Les chiffres de la partie 3D du diaporama viennent de commits locaux d'IX qui ne sont pas poussés ; le cours ne les reproduit pas.
- Le diaporama français a avancé depuis la copie anglaise ; reste à savoir si la copie doit le suivre.

## Questions ouvertes

- La documentation d'IX devrait-elle dire quelle image miroir est chaque nœud nommé, pour que comparer à une table ne demande pas les deux ?
- La documentation d'IX dit que tout entrelacs amphichiral a *V*(*t*) = *V*(1/*t*) ([`jones.rs`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/jones.rs#L42-L43), [`knot.rs`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-agent/src/skills/knot.rs#L64)). Deux anneaux accrochés sont leur propre image miroir une fois les sens oubliés, et pourtant ni `s1^2` ni `s1^-2` n'a la symétrie : la documentation devrait-elle dire que l'image miroir doit garder les sens ?
- Un workflow de CI devrait-il lancer `check.sh` sur trois OS, comme le font les workflows des autres cours ? En ajouter un touche `.github/`, que relit le propriétaire du dépôt.
