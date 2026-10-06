---
title: Parler en nœuds — Mission
description: 'Écrire les nœuds comme un texte qu''IX peut vérifier — d''abord deux diaporamas, l''original français et sa copie anglaise, puis les mots de tresse, leur fermeture et le polynôme de Jones calculé par le crochet de Kauffman, vérifié contre les valeurs qu''affirment les tests d''IX et contre le Knot Atlas, avec un journal dont chaque entrée peut être rejouée.'
sidebar:
  label: Mission
  order: 0
---

## Les deux diaporamas

Le cours part d'un diaporama construit pendant qu'IX apprenait à lire, vérifier et dessiner des nœuds. Il existe en deux langues :

- **[Parler en nœuds](https://claude.ai/artifact/7v3cgP2wAARzvxgDgA8iEq)** : l'original, en français, 52 diapositives.
- **[Speaking in Knots](https://claude.ai/artifact/V9yPov2hxYxNWZApXrNxYF)** : sa copie anglaise, diapositive par diapositive, faite à partir de la version `1791174928-7d71` du diaporama français.

Le diaporama traverse neuf parties : pourquoi un nœud a besoin d'un texte qu'IX peut vérifier ; les quatre façons d'écrire un nœud, avec le code de Gauss en détail ; ce qu'IX vérifie et comment il refuse ; les mots de tresse et les noms de la table des nœuds ; des exemples, du texte au rendu final dans ComfyUI ; les nœuds marins en 3D, dessinés à la main, vérifiés et mis en volume par IX, puis rendus ; ce qu'IX tire des nœuds (erreurs de nouage, invention, pipelines, fichiers `.knot` et bandes dessinées de Jean-Pierre Petit) ; l'état des pull requests ; et la méthode, avec ses relectures adverses.

:::caution[Ce que le cours reproduit, et ce qu'il ne reproduit pas]
Une partie seulement de ce que montre le diaporama est dans le code poussé d'IX. Les mots de tresse et le polynôme de Jones sont dans la [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366), poussée, testée par la CI d'IX et encore ouverte. Le code de Gauss, le langage `.knot`, la corde posée et la boucle 3D vivent sur des branches locales qui ne sont pas encore poussées : leurs chiffres viennent du diaporama, et le cours ne les reproduit pas. La leçon 1 n'enseigne que ce qui se vérifie depuis le code poussé, et le [journal](journal/) dit comment.
:::

## Comment ce cours est testé

Le code du cours est dans [`code/speaking-in-knots`](https://github.com/spareilleux/learn/tree/main/code/speaking-in-knots) : un script Python qui calcule le polynôme de Jones de la fermeture d'une tresse par la somme d'états du crochet de Kauffman, avec la seule bibliothèque standard. `check.sh` le lance contre chaque valeur qu'affirment les tests d'IX au commit [`e8684cf`](https://github.com/GuitarAlchemist/ix/tree/e8684cf) (19 vérifications), le lance sur chaque mot de tresse cité par les leçons, lance une vérification par mutation (six erreurs volontaires, dont chacune doit faire échouer la première vérification), et compare chaque sortie aux fichiers de `expected/`. Aucun workflow de CI ne le lance encore : il a été lancé à la main sous Windows 11 avec Python 3.14.3. Le côté IX est testé par la CI d'IX.

## Pourquoi j'apprends cela

Un nœud dessiné sur papier est facile à montrer et difficile à vérifier. Un nœud écrit comme un texte peut être vérifié par un programme : combien de brins il a, s'il se ferme en une boucle ou en plusieurs, et si deux textes décrivent le même nœud. IX, la boîte à outils Rust de l'écosystème GuitarAlchemist, a appris à le faire, et ce cours suit ce qu'il a appris, une pièce vérifiable à la fois.

## À qui s'adresse ce cours

Vous écrivez du code, et vous n'avez jamais étudié la théorie des nœuds. Aucune mathématique au-delà des polynômes n'est nécessaire : les leçons définissent chaque objet avant de s'en servir, et chaque nombre qu'elles citent vient d'une exécution que vous pouvez refaire. Lire du Rust aide à suivre le code d'IX, mais n'est pas indispensable.

## À la fin de ce cours, je saurai

- écrire un nœud ou un entrelacs comme un mot de tresse, et dire de quoi est faite sa fermeture ;
- calculer un polynôme de Jones par le crochet de Kauffman, et distinguer un nœud de son image miroir ;
- lire une table de nœuds, en sachant quels choix de chiralité elle fait ;
- dire ce qu'IX vérifie dans le texte d'un nœud et quand il le refuse ;
- rejouer chaque entrée du journal du cours, et en vérifier le résultat.

## Plan

| # | Leçon | En termes de développeur |
|---|---|---|
| 1 | [Les mots de tresse et le polynôme de Jones](01-braid-words/) | un parseur, une permutation, et une somme sur 2^n cas |
| 2 | Le code de Gauss : un nœud comme la liste de ses croisements | un format de sérialisation avec un validateur |
| 3 | Ce qu'IX refuse, et pourquoi | des erreurs typées |
| 4 | Les nœuds marins en 3D : d'un dessin à un tube vérifié | un pipeline géométrique avec des contrôles à chaque étape |
| — | [Journal](journal/) | |

Les leçons 2 à 4 sont le plan : chacune attend que le code d'IX qu'elle enseigne soit poussé.

## Ressources

- IX, [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366) : la crate `ix-knot` et la skill `knot.braid`, au commit [`e8684cf`](https://github.com/GuitarAlchemist/ix/tree/e8684cf).
- [The Knot Atlas](https://katlas.org/), la table de nœuds à laquelle le cours se compare.
- J. W. Alexander, « A lemma on systems of knotted curves », *Proceedings of the National Academy of Sciences* 9 (1923), 93–95 : tout nœud et tout entrelacs est la fermeture d'une tresse.
- L. H. Kauffman, « State models and the Jones polynomial », *Topology* 26 (1987), 395–407 : le crochet que calcule la leçon.
