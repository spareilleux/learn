---
module_id: gas-007-distinguish-body-poles-from-string-partials
department: guitar-acoustics
course: "Distinguer les pôles de caisse des partiels de corde"
level: intermediate
prerequisites: ["gas-005-separate-a-partial-peak-from-a-period", "gas-006-relate-pluck-position-to-string-modes", "aud-007-translate-attack-coefficients-into-time"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer les pôles de caisse des partiels de corde

> **Portée du brouillon.** Inspection du code public et calculs pédagogiques de filtres en arithmétique réelle. Les revues humaines technique, linguistique, musicale et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun nouvel enregistrement de guitare, rendu natif/WASM ou flux de travail [ComfyUI](https://docs.comfy.org/) n'ont été exécutés.

## La question du projet

Un agent observe un pic spectral et propose de modifier la fréquence de caisse d'une guitare. Quel paramètre du modèle cela modifierait-il, et ce paramètre est-il égal au pic observé ? [GAS-005](gas-005-separate-a-partial-peak-from-a-period.md) distingue un partiel d'une période ; [GAS-006](gas-006-relate-pluck-position-to-string-modes.md) modélise l'excitation. Nous examinons ici l'étage de caisse qui suit, à la révision publique de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`.

Le [constructeur](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L124-L135) installe cinq sections. Ce sont des paramètres du code, et non des modes de caisse mesurés :

| Paramètre de fréquence des pôles, Hz | Rayon des pôles r | Gain du numérateur g |
| --- | --- | --- |
| 110 | 0.95 | 0.08 |
| 240 | 0.96 | 0.10 |
| 530 | 0.97 | 0.08 |
| 1200 | 0.98 | 0.03 |
| 2400 | 0.92 | 0.02 |

## 1. Déduire la section avant d'interpréter son nom

La [récurrence](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L23-L44) possède deux états de sortie retardés, initialement nuls. Pour une fréquence d'échantillonnage déclarée Fs et une fréquence des pôles f0 :

```text
omega0 = 2*pi*f0/Fs
a1 = 2*r*cos(omega0)
a2 = -r^2
y[n] = g*x[n] + a1*y[n-1] + a2*y[n-2]
H(z) = g / (1 - a1*z^-1 - a2*z^-2)
     = g / (1 - 2*r*cos(omega0)*z^-1 + r^2*z^-2)
```

Les pôles sont de rayon r et d'angles plus et moins omega0. Tous les rayons énumérés sont inférieurs à 1 ; les sections linéaires idéales isolées sont donc stables. La [convention biquad du W3C](https://www.w3.org/TR/audio-eq-cookbook/) écrit les coefficients du dénominateur avec des signes plus et soustrait leurs sorties retardées. Ses signes de dénominateur ne doivent pas être copiés directement dans la récurrence additive de ce code.

### Exercice 1 — Faire correspondre les signes

Pour la section à 110 Hz, donnez a2 dans la récurrence et le coefficient de z^-2 au dénominateur. g = 0.08 signifie-t-il un gain d'amplitude de 0.08 à toutes les fréquences ?

> **Réponse:** a2 = -0.9025 ; le coefficient du dénominateur est +0.9025. Non : g est un coefficient du numérateur. Le dénominateur de rétroaction modifie la réponse en fréquence.

## 2. Un angle de pôle n'est pas nécessairement un maximum de gain

La [démonstration à deux pôles de Julius O. Smith](https://www.dsprelated.com/freebooks/filters/Two_Pole.html) distingue explicitement la fréquence des pôles du gain maximal exact. Pour cette section à numérateur constant, minimiser le carré du module du dénominateur sur les fréquences de 0 à Nyquist donne :

```text
c = cos(omega0)*(1+r^2)/(2*r)
omega_peak = acos(clamp(c, -1, 1))
f_peak = Fs*omega_peak/(2*pi)
```

À Fs = 44100 Hz, les [calculs pédagogiques de réponse](../../../../code/streeling/evidence/filter-phase-2026-10-22/body-response.json) donnent :

| Paramètre de fréquence des pôles, Hz | Maximum isolé, Hz, environ |
| --- | --- |
| 110 | 0 |
| 240 | 0 |
| 530 | 485.059638 |
| 1200 | 1191.675201 |
| 2400 | 2330.439876 |

La première section a un module d'environ 29.268259 en continu et de 27.306424 à 110 Hz. Une réponse impulsionnelle oscillante amortie peut avoir son plus grand module de réponse en fréquence à la composante continue. Ce résultat décrit la section mathématique isolée, et non un nouvel enregistrement, les pics de toute la banque ou le moteur non linéaire complet.

### Exercice 2 — Lire l'étiquette 110 Hz

À Fs = 44100 Hz, l'affirmation « le maximum de la section à 110 Hz doit se situer à 110 Hz » est-elle étayée ? Expliquez ce que signifie le cosinus borné ci-dessus lorsque c est supérieur à 1.

> **Réponse:** Non. Le minimum du dénominateur se produit à l'extrémité omega = 0 lorsque le cosinus optimal sans contrainte dépasse 1. Le paramètre fixe l'angle des pôles ; le maximum de gain isolé obtenu se situe en continu dans ce modèle. Le bornage sélectionne l'extrémité du domaine fréquentiel, et non un étalonnage physique corrigé.

## 3. Sommer les réponses complexes avant de prendre le module

Le [code de mélange](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L483-L496) envoie la somme normalisée des cordes dans chaque section, additionne leurs sorties, puis combine les signaux de caisse et de cordes :

```text
H_body(omega) = sum_i H_i(omega)
H_dry(omega) = 0.55 + 0.45*H_body(omega)
```

À 110 Hz, le module mathématique du signal sec est d'environ 34.953699. Additionner plutôt les modules des modes donne environ 35.364828. Les phases relatives expliquent la différence. Aucun nombre n'est un gain de sortie mesuré du moteur complet : la réverbération et les non-linéarités de sortie suivent cet étage, et la normalisation des voix actives peut modifier le comportement en amont.

### Exercice 3 — Combiner la banque

Choisissez la bonne expression : le module de la réponse complexe sèche ci-dessus, ou 0.55 plus 0.45 fois la somme des modules des sections. Expliquez pourquoi l'autre expression n'est ici qu'une borne supérieure.

> **Réponse:** Prenez le module après la somme complexe. L'inégalité triangulaire le borne par 0.55 plus 0.45 fois la somme des modules, mais l'égalité exige des phases alignées. Le calcul à 110 Hz montre que l'égalité n'y est pas satisfaite.

## 4. Un filtre linéaire de caisse ne réaccorde pas une sinusoïde en régime établi

Considérez une entrée pédagogique en régime établi contenant seulement 82.4069 Hz et 164.8138 Hz. Dans le modèle isolé de caisse linéaire invariant dans le temps, chaque sinusoïde conserve sa fréquence et acquiert un gain complexe. Un paramètre de fréquence des pôles de 110 Hz n'insère pas une nouvelle raie spectrale permanente à 110 Hz. Les transitoires de démarrage peuvent osciller ; la réverbération, la variation dans le temps et l'écrêtage de sortie doivent être évalués séparément.

### Exercice 4 — Distinguer le régime établi du démarrage

Un agent affirme que le paramètre de pôle à 110 Hz donne à chaque entrée de E à vide une nouvelle tonalité permanente à 110 Hz. Donnez un contre-exemple avec l'entrée à deux fréquences ci-dessus et précisez pourquoi un transitoire oscillant initial ne l'invaliderait pas.

> **Réponse:** La sortie en régime établi de cet étage linéaire invariant dans le temps contient toujours seulement 82.4069 Hz et 164.8138 Hz, avec des amplitudes et phases modifiées. Sa réponse naturelle décroissante peut se produire au démarrage ; c'est différent d'une raie spectrale supplémentaire entretenue par l'entrée. Cet argument ne couvre pas l'écrêtage non linéaire du moteur complet.

## 5. Distinguer une affirmation physique d'un filtre synthétique utile

La [discussion du modèle de chevalet de Smith](https://dsprelated.com/freebooks/pasp/Building_Synthetic_Guitar_Bridge.html) distingue l'admittance du chevalet, le couplage des cordes et le rayonnement. L'étage examiné du moteur est une banque de filtres de sortie alimentée par la somme des cordes. Des noms tels que table d'harmonie dans les commentaires n'établissent ni géométrie mesurée, ni gains modaux étalonnés, ni modèle passif de chevalet recouplé à chaque corde.

### Exercice 5 — Délimiter la prochaine expérience

Avant de qualifier une banque modifiée de « caisse de guitare plus exacte », identifiez les preuves actuelles et nommez les mesures et contrôles de comparaison manquants. Où faut-il conserver les signaux appariés pour un test isolé ?

> **Réponse:** Les preuves actuelles sont le code à une révision précise et les calculs pédagogiques de filtres. Une affirmation d'exactitude physique exige un instrument et un parcours de mesure définis, des données de réponse étalonnées, les emplacements d'excitation et d'observation, des critères d'ajustement et des comparaisons sur des données réservées. Préservez l'entrée de somme normalisée des cordes et la sortie sèche avant réverbération, avec des horloges et échelles correspondantes ; gardez l'écrêtage et la réverbération en aval séparés. Une préférence d'auditeur exige sa propre évaluation contrôlée. [AUD-008](../../audio-engineering/en/aud-008-measure-a-filter-with-paired-input-and-output.md) développe la mesure appariée.

## Travail de l'apprenant avec accès aux sources

Sans copier les réponses, préparez une courte revue d'une commande proposée de « pic de caisse à 110 Hz ». Incluez les signes de la récurrence, les calculs des pics à l'extrémité du domaine pour les sections à 110 Hz et 240 Hz à Fs = 44100 Hz, les gains de la première section en continu et à 110 Hz, ainsi que le module de la réponse sèche de la banque à 110 Hz comparé à l'alternative fondée sur la somme des modules. Ajoutez le contre-exemple à deux fréquences en régime établi et un plan de mesure délimité. Consignez l'aide et l'incertitude. La [grille d'évaluation de la revue](../../../../code/streeling/evidence/filter-phase-2026-10-22/reviewer-rubric.json) est préparée ; aucune tentative d'apprenant n'est enregistrée.

Le [relevé des sources](../../../../code/streeling/evidence/filter-phase-2026-10-22/primary-readback.json) lie les fichiers publics immuables. Les calculs utilisent une arithmétique de plus grande précision sur les paramètres décimaux du code, et non une reproduction de Rust f32 exacte au bit près. Ce cours seul n'entraîne aucune modification du code, réparation à l'exécution ou amélioration acoustique.
