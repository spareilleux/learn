---
title: Diario
description: 'Notas de avance fechadas del curso Hablar en nudos — la presentación francesa y su copia en inglés, una suma de estados en Python comprobada contra los valores que afirman las pruebas de IX, seis errores deliberados que detecta, el Knot Atlas que imprime la imagen especular del trébol, lo que encontró una revisión independiente, y bloques para repetir que permiten a una persona o a un agente volver a ejecutar cada entrada y comprobarla.'
sidebar:
  order: 99
---

:::note[Repetir una entrada]
Cada entrada fechada termina con bloques **Para repetir**: dónde ejecutar, el comando exacto, su entrada, la salida esperada y la comprobación que decide. Una persona o un agente puede volver a ejecutarlos y decir si la entrada sigue siendo válida. Un bloque que no se ejecutó en la máquina del autor lo dice.
:::

## Progreso

- [x] La presentación francesa, *Parler en nœuds*, y su copia en inglés, *Speaking in Knots*, 52 diapositivas cada una
- [x] `check.sh`: la suma de estados contra los 26 valores que afirman las pruebas de IX sobre palabras de hasta 6 cruces, las palabras de trenza que citan las lecciones y la comprobación por mutación
- [x] Lección 1: las palabras de trenza y el polinomio de Jones
- [x] Traducciones al francés y al español
- [x] Una revisión independiente del curso contra el código fuente de IX, y sus siete hallazgos bloqueantes corregidos
- [ ] Un workflow de CI que ejecute `check.sh` en Windows, Linux y macOS
- [ ] Lección 2: el código de Gauss (espera a que se publique el código de Gauss de IX)
- [ ] Lección 3: lo que IX rechaza, y por qué
- [ ] Lección 4: los nudos marineros en 3D (espera a que se publique la cuerda apoyada de IX)

## Experimentos

Cada hipótesis de abajo se escribió antes de la medición, en [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/preregistration.md). Se guardó sin cambios en el mismo commit que los resultados, así que el historial no puede mostrar que se escribió primero: eso descansa en la palabra del autor. Cuando no se escribió ninguna hipótesis, la fila lo dice.

| Pregunta | Hipótesis | Resultado | Veredicto | Dónde |
|---|---|---|---|---|
| ¿Una suma de estados calculada fuera de IX da los valores que afirman las pruebas de IX en `e8684cf`? | Sí: cada polinomio de Jones afirmado, escrito de forma idéntica en el formato de texto de IX, y las componentes y torsiones afirmadas. | 26 de 26 comprobaciones coinciden: cada polinomio de Jones, número de componentes, torsión, permutación y simetría que afirman las pruebas de IX sobre palabras de hasta 6 cruces. La primera ejecución comprobaba 19 y lo llamaba cada valor; la revisión del 2026-10-06 encontró las otras 7. La hipótesis también llamaba independiente al script: sigue la construcción de la función auxiliar `state_sum` que ya está en las pruebas de IX, así que la coincidencia muestra que los valores se reproducen fuera de IX, no que se obtuvieran de forma independiente. | Confirmada | [2026-10-05](#2026-10-05--las-dos-presentaciones-y-el-polinomio-de-jones-comprobado-de-tres-formas) · [2026-10-06](#2026-10-06--lo-que-encontró-una-revisión-independiente) · [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) |
| ¿El Knot Atlas imprime, para el trébol, el polinomio del `s1^3` de IX? | No: imprime el polinomio especular, −q⁻⁴ + q⁻³ + q⁻¹. | 3_1 imprime `- q^{-4} + q^{-3} + q^{-1}`, el polinomio de `s1^-3`. L2a1 hace lo mismo con el enlace de Hopf; 4_1 y L6a4 coinciden exactamente con IX. La razón que daba la hipótesis, que el Atlas dibuja el trébol izquierdo, no se comprobó por separado. | Confirmada | [2026-10-05](#2026-10-05--las-dos-presentaciones-y-el-polinomio-de-jones-comprobado-de-tres-formas) |
| ¿La primera comprobación detecta errores deliberados en el script? | Ninguna escrita de antemano. | 6 de 6 mutantes la hacen fallar; cada uno sigue coincidiendo con IX en 16 a 23 de las 26 comprobaciones. | Sin veredicto: no se registró hipótesis | [2026-10-05](#2026-10-05--las-dos-presentaciones-y-el-polinomio-de-jones-comprobado-de-tres-formas) · [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py) |

## 2026-10-05 — Las dos presentaciones, y el polinomio de Jones comprobado de tres formas

**Las presentaciones.** La presentación francesa, *Parler en nœuds*, se construyó mientras IX aprendía a leer, comprobar y dibujar nudos. La copia en inglés la sigue diapositiva por diapositiva, a partir de su versión `1791174928-7d71`: un cambio posterior de la presentación francesa no se traslada solo. La maquetación se comparó de forma mecánica, diapositiva por diapositiva: las mismas etiquetas y los mismos atributos, y solo difieren el texto, el texto alternativo de las imágenes y las etiquetas de sección; cada imagen apunta a una copia guardada en la presentación inglesa.

**Lo que se puede comprobar.** De lo que muestra la presentación, solo las palabras de trenza, el polinomio de Jones y una disposición 3D de las hebras están en el código publicado de IX, en la [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366), en el commit `e8684cf`. Su ejecución de CI [37216487957](https://github.com/GuitarAlchemist/ix/actions/runs/37216487957) superó el job build-and-test en Ubuntu y Windows, con Rust stable y nightly. Su informe de riesgo falla, y la pull request espera una revisión humana. El resto (código de Gauss, archivos `.knot`, cuerda apoyada, bucle 3D) está en ramas locales que no se han publicado, y esta entrada no lo comprueba.

**Una suma de estados contra las pruebas de IX.** Antes de escribir código, anoté la hipótesis en [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/preregistration.md). Después [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) recalculó 19 valores que afirman las pruebas de IX, y los 19 coincidían; la entrada siguiente añade los 7 que faltaban. El prerregistro dice que el script es independiente y que se escribió a partir de la definición de los manuales. Es una exageración: su construcción (un union-find sobre el diagrama cerrado, un nodo por nivel y posición) es la de la función auxiliar `state_sum` de las propias pruebas de IX, y esas pruebas ya la comparan con la evaluación de Temperley–Lieb de IX en 150 palabras. Lo que añade la coincidencia es que los valores se comprueban sin Rust ni el repositorio de IX. La comprobación independiente es la siguiente.

**El Knot Atlas.** La página del trébol, 3_1, imprime el polinomio de `s1^-3`, como predecía la segunda hipótesis, y la del enlace de Hopf, L2a1, el de `s1^-2`. El nudo en ocho (4_1) y los anillos de Borromeo (L6a4), cada uno su propia imagen especular, coinciden exactamente con los polinomios de IX. Una tabla e IX pueden dibujar imágenes especulares opuestas con el mismo nombre; la [lección 1](../01-braid-words/) hace que el lector compruebe las dos.

**Seis mutantes.** [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py) cambia una línea del script cada vez y exige que la primera comprobación falle. Los seis la hacen fallar. Ninguno lo rompe todo: cada mutante sigue coincidiendo con IX en la mayoría de las comprobaciones, por eso la comprobación las compara todas y no solo algunas.

**Para repetir 1: la comprobación del curso.** Ejecutado en la máquina del autor: Windows 11, Git Bash, Python 3.14.3.

- Dónde: la raíz de un clon de [spareilleux/learn](https://github.com/spareilleux/learn), en el commit que añade esta entrada o posterior.
- Entrada: ninguna. Python 3, solo la biblioteca estándar; `PYTHON=…` elige otro intérprete.
- Comando:

  ```bash
  bash code/speaking-in-knots/check.sh
  ```

- Salida esperada, siendo la primera línea tu versión de Python:

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

- Comprobación: estado de salida 0, y cada línea después de la primera empieza por `ok`. Una línea `FAIL` sigue a la diferencia entre la salida y el archivo de `expected/`.

**Para repetir 2: las propias pruebas de IX en el commit fijado.** No se ejecutó en la máquina del autor; lo ejecutó la CI de IX.

- Dónde: un clon de [GuitarAlchemist/ix](https://github.com/GuitarAlchemist/ix), con una cadena de herramientas de Rust.
- Entrada: ninguna.
- Comando:

  ```bash
  git fetch origin pull/366/head
  git checkout e8684cf
  cargo test -p ix-knot
  ```

- Salida esperada: entre las pruebas superadas, `jones::tests::known_knots_and_links`, `jones::tests::the_reef_knot_is_symmetric_and_the_granny_is_not` y `jones::tests::the_algebra_agrees_with_the_state_sum_and_the_markov_moves`, y después `test result: ok`. El número de pruebas no se anota aquí.
- Comprobación: estado de salida 0. Como referencia, la ejecución de CI 37216487957 ejecutó `cargo test --workspace` y la superó.

**Para repetir 3: el Knot Atlas.** Ejecutado en la máquina del autor el 2026-10-05; necesita la red.

- Dónde: en cualquier sitio, con `bash`, `curl` y `grep`.
- Entrada: las cuatro páginas 3_1, L2a1, 4_1 y L6a4 de [katlas.org](https://katlas.org/).
- Comando:

  ```bash
  for k in 3_1 L2a1 4_1 L6a4; do
    printf '%s: ' "$k"
    curl -s -A "streeling-review/1.0" "https://katlas.org/wiki/$k" | grep -A3 'Jones polynomial' | grep -o 'displaystyle{.*}\[/math\]' | head -1
  done
  ```

- Salida esperada:

  ```text
  3_1: displaystyle{ - q^{-4} + q^{-3} + q^{-1}  }[/math]
  L2a1: displaystyle{ -\frac{1}{\sqrt{q}}-\frac{1}{q^{5/2}} }[/math]
  4_1: displaystyle{ q^2+ q^{-2} -q- q^{-1} +1 }[/math]
  L6a4: displaystyle{ -q^3- q^{-3} +3 q^2+3 q^{-2} -2 q-2 q^{-1} +4 }[/math]
  ```

- Comprobación: leyendo *q* como *t*, 3_1 es la línea `s1^-3` de `expected/oracle.txt` y L2a1 es `expected/hopf-mirror.txt`; 4_1 es la línea `s1 s2^-1 s1 s2^-1` y L6a4 la línea `s1 s2^-1 s1 s2^-1 s1 s2^-1`. Una página de wiki puede cambiar: una salida distinta significa volver a comparar, no que IX esté mal.

## 2026-10-06 — Lo que encontró una revisión independiente

Antes de la fusión, un revisor que no había participado en la escritura del curso leyó la pull request contra el código fuente de IX en `e8684cf`. Señaló siete problemas bloqueantes. Cada uno se comprobó contra el código fuente antes de corregirlo:

- **El sentido de lectura era el especular.** La lección 1 disponía las hebras de arriba abajo. IX dispone una trenza con *y* hacia arriba, y [`layout.rs`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/layout.rs#L26-L39) dice que una imagen con *y* hacia abajo muestra la trenza especular: un lector que dibujaba `s1^3` como decía la lección obtenía el trébol izquierdo, donde IX calcula el derecho. La lección lee ahora las trenzas de abajo arriba, y dice por qué.
- **«Cada valor que afirman las pruebas de IX» eran 19 valores.** Al script le faltaban la simetría del nudo en ocho, la torsión de una trenza especular, las tres identidades de la prueba del nudo llano y el nudo de la abuela, y la torsión y la permutación que afirman las pruebas de la herramienta `ix_braid`. Ahora comprueba las 26, siempre en coincidencia, y nombra las dos pruebas fuera de su alcance (63 y 64 cruces, y las 150 palabras generadas de IX).
- **El código publicado de IX también tiene una disposición 3D** de las hebras, `layout.rs`, que la entrada anterior omitía.
- **Los comandos difieren entre Windows y los otros sistemas** (`python` frente a `python3`): la lección es ahora una página `.mdx` con una pestaña por sistema, como pide AGENTS.md.
- **Python y Rust** están ahora enlazados en su primera mención en la lección.
- **Linux y macOS nunca se ejecutaron**, lo que ahora dice *Por verificar*.
- **La presentación inglesa era privada** cuando la revisión la leyó, mientras que la francesa ya estaba compartida con cualquiera que tenga el enlace. El curso no se fusiona antes de que lo estén las dos.

La revisión también señaló que la presentación francesa ha cambiado desde la copia: versión `1791213311-03e2` el 2026-10-06, frente a `1791174928-7d71` para la fuente de la copia. La copia inglesa no la sigue.

**Para repetir 4: las 26 comprobaciones.** Ejecutado en la máquina del autor: Windows 11, Git Bash, Python 3.14.3.

- Dónde: la raíz de un clon de [spareilleux/learn](https://github.com/spareilleux/learn), en el commit que añade esta entrada o posterior.
- Entrada: ninguna.
- Comando:

  ```bash
  bash code/speaking-in-knots/check.sh > /dev/null && tail -2 code/speaking-in-knots/out/oracle.txt
  ```

- Salida esperada:

  ```text
  26/26 agree with IX at e8684cf
  exit 0
  ```

- Comprobación: exactamente estas dos líneas. `exit 0` es el estado del propio script, que `check.sh` añade a su salida.

## Por verificar

- `check.sh` en Linux y macOS: solo se ejecutó en Windows 11.
- Para repetir 2 en la máquina del autor: el curso solo se apoya en la CI de IX para ello.
- Si el Knot Atlas dibuja el trébol izquierdo bajo 3_1, la razón que daba la segunda hipótesis; solo se comparó el polinomio.
- La pull request #366 sigue abierta: los enlaces a IX apuntan al commit `e8684cf` y siguen siendo válidos después de una fusión, pero el código puede cambiar antes.
- Las cifras de la parte 3D de la presentación vienen de commits locales de IX que no se han publicado; el curso no las reproduce.
- La presentación francesa ha avanzado desde la copia inglesa; queda por decidir si la copia debe seguirla.

## Preguntas abiertas

- ¿Debería la documentación de IX decir qué imagen especular es cada nudo con nombre, para que comparar con una tabla no exija las dos?
- ¿Debería un workflow de CI ejecutar `check.sh` en tres sistemas operativos, como hacen los workflows de los otros cursos? Añadir uno toca `.github/`, que revisa el propietario del repositorio.
