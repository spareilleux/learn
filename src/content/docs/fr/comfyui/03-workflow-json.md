---
title: '3. Les workflows en JSON : le format de l''interface, le format de l''API, et les différences'
description: 'Les deux formats JSON d''un graphe ComfyUI — le workflow qu''enregistre le frontend, avec les positions, les tables de liens et les valeurs de widgets par position, et le prompt qu''exécute le serveur — convertis de l''un à l''autre en C# octet pour octet comme le frontend, les métadonnées que ComfyUI écrit dans les fichiers PNG, un workflow validé hors ligne avec /object_info et par le serveur, et des comparaisons qui ignorent la mise en page.'
sidebar:
  order: 3
---

Code : les trois fichiers JSON du graphe de la leçon 1 dans [`workflows/`](https://github.com/spareilleux/learn/tree/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows), la conversion, la validation et la comparaison dans [`csharp/Workflow.cs`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Workflow.cs), le lecteur de PNG dans [`csharp/Png.cs`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Png.cs), et les définitions de nœuds qu'ils utilisent dans [`data/object_info.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/data/object_info.json).

## Deux formats pour un graphe

ComfyUI stocke un graphe dans deux formats JSON, et tu rencontreras les deux.

- **Le workflow**, ou format de l'interface, est ce que le frontend enregistre avec File → Save, ce que tu fais glisser dans le navigateur, et ce que sont les modèles de workflows. Il décrit le dessin : où est chaque nœud, quelle est sa taille, quels liens relient quels emplacements, et les valeurs des widgets.
- **Le prompt**, ou format de l'API, est ce qu'exécute le serveur. Le frontend le construit quand tu appuies sur Run, et File → Export Workflow (API) l'enregistre. Il ne contient que les types de nœuds, les entrées et les liens.

La [page sur le format de l'API](https://docs.comfy.org/development/api-development/workflow-api-format) le dit ainsi : « API format omits UI metadata (positions, colors, groups, node sizes) that is only needed for visual editing in the frontend. », c'est-à-dire que le format de l'API omet les métadonnées d'interface, positions, couleurs, groupes et tailles des nœuds, qui ne servent qu'à l'édition visuelle. Le tableau de la même page dit que le format d'enregistrement indexe les nœuds par « Node titles or labels », par titres ou libellés ; en réalité, les deux formats utilisent l'identifiant numérique du nœud, comme le montrent les fichiers ci-dessous.

Pour obtenir une vraie paire, le cours a chargé le fichier API de la leçon 1 dans le frontend, version 1.52.7, et a laissé le frontend exporter les deux formats, depuis la console JavaScript du navigateur :

```js
await app.loadApiJson(apiWorkflow, '01-txt2img');
const { workflow, output } = await app.graphToPrompt();
```

`workflow` est devenu [`01-txt2img.ui.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.ui.json), 6 660 octets, et `output` est devenu [`01-txt2img.exported.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.exported.api.json), 1 792 octets. `app` est l'objet global du frontend ; ces deux fonctions sont celles qu'appellent ses menus, mais ce n'est pas une API documentée, donc les entrées de menu restent le moyen stable.

| | Workflow (format de l'interface) | Prompt (format de l'API) |
|---|---|---|
| Niveau supérieur | un objet avec `nodes`, `links`, `groups`, `extra` et `version` | un objet dont les clés sont les identifiants des nœuds |
| Un nœud | `id`, `type`, `pos`, `size`, `order`, `mode`, `inputs`, `outputs`, `widgets_values` | `class_type`, `inputs`, et `_meta.title` |
| Une valeur de widget | par position, dans `widgets_values` | par nom, dans `inputs` |
| Un lien | une ligne de la table `links` du niveau supérieur, référencée par son identifiant depuis les deux nœuds | `["4", 1]` dans l'entrée qui le reçoit |
| Nœuds propres au frontend, comme les notes | conservés | supprimés |
| Schéma | [workflow JSON 0.4](https://docs.comfy.org/specs/workflow_json_0.4), et une version [1.0](https://docs.comfy.org/specs/workflow_json) plus récente | aucun publié ; c'est la validation du serveur qui le définit |

## Le format du workflow

Voici le nœud `KSampler` dans le fichier d'interface, sans son `widgets_values_named`, dont il est question plus bas :

```json
{
  "id": 3,
  "type": "KSampler",
  "pos": [970, 130],
  "size": [270, 262],
  "flags": {},
  "order": 4,
  "mode": 0,
  "inputs": [
    { "name": "model", "type": "MODEL", "link": 10 },
    { "name": "positive", "type": "CONDITIONING", "link": 11 },
    { "name": "negative", "type": "CONDITIONING", "link": 12 },
    { "name": "latent_image", "type": "LATENT", "link": 13 }
  ],
  "outputs": [
    { "name": "LATENT", "type": "LATENT", "links": [16] }
  ],
  "properties": { "Node name for S&R": "KSampler" },
  "widgets_values": [42, "randomize", 25, 7, "euler", "normal", 1]
}
```

Et la table `links`, où chaque ligne est `[link id, origin node, origin slot, target node, target slot, type]` :

```json
[[10, 4, 0, 3, 0, "MODEL"], [11, 6, 0, 3, 1, "CONDITIONING"], [12, 7, 0, 3, 2, "CONDITIONING"],
 [13, 5, 0, 3, 3, "LATENT"], [14, 4, 1, 6, 0, "CLIP"], [15, 4, 1, 7, 0, "CLIP"],
 [16, 3, 0, 8, 0, "LATENT"], [17, 4, 2, 8, 1, "VAE"], [18, 8, 0, 9, 0, "IMAGE"]]
```

Trois choses surprennent un développeur qui s'attend à un format de données :

- **Les liens sont stockés à trois endroits.** Le lien 10 est une ligne de `links`, un identifiant dans l'entrée `model` du nœud 3, et un identifiant dans la sortie `MODEL` du nœud 4. Un outil qui modifie un endroit doit modifier les autres.
- **Les valeurs des widgets sont positionnelles.** `widgets_values` a sept éléments pour six entrées de type widget. Le deuxième, `"randomize"`, est le widget *control after generate* que le frontend ajoute après toute graine : après chaque exécution, il remplace la graine par un nombre aléatoire, ou lui ajoute ou lui retire un. Le serveur ne le voit jamais.
- **La mise en page fait partie des données.** Déplace un nœud d'un pixel et `pos` change. Une comparaison de fichiers d'interface dans le gestionnaire de versions mélange les changements de mise en page avec ceux qui comptent.

L'export contient aussi un objet `widgets_values_named` à côté de `widgets_values`, avec les mêmes valeurs par nom. Le schéma ne le mentionne pas, et le convertisseur du cours ne l'utilise pas.

## Du workflow au prompt

Convertir, c'est résoudre chaque identifiant de lien par la table `links`, et nommer chaque valeur de widget. Les noms viennent du serveur : `/object_info` liste les entrées de chaque nœud, dans l'ordre, sous `input_order`. Le convertisseur C# du cours suit les règles du frontend, dans [`Workflow.FromUi`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Workflow.cs) :

```csharp
var values = new Queue<JsonNode?>(node["widgets_values"] as JsonArray ?? []);
var order = definition["input_order"]?["required"]?.AsArray().Concat(definition["input_order"]?["optional"]?.AsArray() ?? []) ?? [];
foreach (string name in order.Select(n => n!.GetValue<string>()))
{
    var spec = InputSpec(definition, name)!;
    if (!IsWidget(spec) || values.Count == 0) continue;
    inputs[name] = values.Dequeue()?.DeepClone();
    // A seed has a second widget, "control after generate", that the server never sees.
    if (spec.Count > 1 && spec[1]?["control_after_generate"]?.GetValue<bool>() == true && values.Count > 0)
        values.Dequeue();
}
foreach (var input in (node["inputs"] as JsonArray ?? []).Select(i => i!.AsObject()))
    if (input["link"]?.GetValue<int>() is int linkId)
    {
        var (origin, slot) = links[linkId];
        inputs[input["name"]!.GetValue<string>()] = new JsonArray(origin.ToString(), slot);
    }
```

Une entrée est un widget quand son type est `INT`, `FLOAT`, `STRING`, `BOOLEAN`, ou une liste de choix. `seed` est déclarée avec `"control_after_generate": true` dans [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1603), et c'est ainsi que le convertisseur sait qu'il doit sauter la valeur suivante.

`check.sh` exécute le convertisseur sur le fichier d'interface et compare sa sortie avec l'export du frontend : ce sont les mêmes octets, aux fins de ligne près. Le convertisseur est volontairement petit. Il refuse les nœuds de reroutage, les nœuds primitifs, les nœuds contournés et les sous-graphes, qu'un vrai outil devrait gérer ; pour ceux-là, laisse le frontend faire l'export.

Le fichier écrit à la main et l'export du frontend n'ont pas les mêmes octets : l'export ajoute `_meta.title`, ordonne les clés autrement, et écrit `7` là où le fichier avait `7.0`. La commande `diff` du cours compare ce que le serveur utilise, les types de nœuds et les entrées, et traite les nombres comme des nombres :

```text
> comfy diff workflows/01-txt2img.api.json workflows/01-txt2img.exported.api.json
same nodes and inputs
```

C'est cette comparaison qu'il faut mettre dans une revue de code. Garde le fichier d'interface si des gens modifient le graphe dans le navigateur, mais relis les changements sur le format de l'API, où une graine modifiée est une ligne modifiée :

```text
> comfy diff workflows/01-txt2img.api.json workflows/03-broken.api.json
~ 3.steps: 25 -> 0
~ 3.sampler_name: "euler" -> "euler_a"
~ 3.negative: ["7",0] -> ["12",0]
~ 3.latent_image: ["5",0] -> ["4",2]
4 differences
```

## Valider un workflow

[`03-broken.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/03-broken.api.json) est le workflow de la leçon 1 avec quatre erreurs : ces quatre lignes de la comparaison. La commande `validate` du cours vérifie ce qu'elle peut hors ligne. Sans définitions de nœuds, elle vérifie la structure : chaque nœud a un `class_type`, chaque lien pointe vers un nœud existant, et il n'y a pas de cycle. Avec les définitions enregistrées depuis le `/object_info` d'un serveur, elle vérifie ce que vérifie le serveur : des types de nœuds connus, les entrées obligatoires, les plages de valeurs et les choix, et que le type de la sortie de chaque lien est celui qu'attend l'entrée.

```text
> comfy validate workflows/03-broken.api.json data/object_info.json
error: node 4 (CheckpointLoaderSimple) input ckpt_name: "sd_xl_base_1.0.safetensors" is not one of the 0 allowed values
error: node 3 (KSampler) input steps: 0 is below the minimum 1
error: node 3 (KSampler) input sampler_name: "euler_a" is not one of the 45 allowed values
error: node 3 (KSampler) input negative: links to node 12, which doesn't exist
error: node 3 (KSampler) input latent_image: expects LATENT, node 4 output 2 is VAE
```

La première erreur ne fait pas partie des quatre : `data/object_info.json` a été enregistré depuis le serveur de la CI, qui n'a aucun modèle, donc la liste des noms de checkpoints autorisés est vide. Le serveur lui-même dit la même chose, puisque les choix d'une entrée à liste déroulante sont les fichiers qu'il trouve sur le disque. Sur un graphe valide, `validate` affiche aussi un ordre dans lequel les nœuds peuvent s'exécuter :

```text
> comfy validate workflows/01-txt2img.api.json
valid; the nodes can run in this order: 4 5 6 7 3 8 9
```

Envoyé au serveur, le workflow cassé est refusé avec un HTTP 400 :

```json
{"error": {"type": "prompt_outputs_failed_validation", "message": "Prompt outputs failed validation", "details": "", "extra_info": {}},
 "node_errors": {
  "4": {"errors": [{"type": "value_not_in_list", "message": "Value not in list",
        "details": "ckpt_name: 'sd_xl_base_1.0.safetensors' not in []", …}], "dependent_outputs": ["9"], "class_type": "CheckpointLoaderSimple"},
  "3": {"errors": [{"type": "exception_during_inner_validation", "message": "Exception when validating inner node",
        "details": "'12'", "extra_info": {…, "exception_type": "KeyError", "traceback": ["  File \"C:\\Users\\…\\ComfyUI\\execution.py\", line 933, in validate_inputs\n    o_class_type = prompt[o_id]['class_type']\n…"]}}], …}}}
```

Le serveur a signalé deux erreurs là où la vérification hors ligne en a trouvé cinq, et la seconde est étrange : elle est rangée sous le nœud 3, mais son `extra_info` nomme l'entrée `samples` et le nœud lié `["3", 0]`, ce qui est l'entrée du nœud 8. Le code l'explique. Le serveur valide en partant de chaque nœud de sortie et en remontant par ses liens. Pour une entrée liée, [`validate_inputs`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L933) lit `prompt[o_id]['class_type']` avant son bloc `try`, donc le lien du nœud 3 vers le nœud 12 manquant a levé une `KeyError` qui a échappé à la validation du nœud 3. Le nœud 8, `VAEDecode`, l'a attrapée en validant son entrée `samples`, et [l'a enregistrée comme résultat du nœud 3](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L962-L979). Les autres entrées du nœud 3 n'ont jamais été vérifiées, ou seulement certaines d'entre elles : `validate_inputs` parcourt les entrées d'un nœud dans l'ordre d'un ensemble Python ([ligne 896](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L896)), qui change d'un démarrage du serveur à l'autre. La réponse contient aussi une trace d'appels Python avec le chemin d'installation du serveur, ce qui est une raison de plus de ne pas exposer le port. Valider hors ligne d'abord donne une meilleure liste d'erreurs ; c'est quand même la réponse du serveur qui tranche.

## Les métadonnées des fichiers PNG

Un fichier PNG est une signature et une liste de chunks, chacun avec une longueur, un type de quatre lettres, des données et un CRC-32 ([spécification PNG](https://www.w3.org/TR/png-3/#11tEXt)). `SaveImage` ajoute un chunk `tEXt` pour le prompt, et un pour chaque clé que le client a envoyée dans `extra_pnginfo`, dans [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1701-L1707) :

```python
metadata = PngInfo()
if prompt is not None:
    metadata.add_text("prompt", json.dumps(prompt))
if extra_pnginfo is not None:
    for x in extra_pnginfo:
        metadata.add_text(x, json.dumps(extra_pnginfo[x]))
```

Le frontend envoie le workflow d'interface dans `extra_pnginfo` ; les clients d'API de ce cours ne le font pas. Le `prompt` est celui que le serveur a validé, et la validation réécrit les valeurs converties : `"cfg": 7.0` ci-dessous vient d'un frontend qui a envoyé `7`, converti par `float(val)` ([`execution.py`, ligne 995](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L995-L997)). Une image mise en file d'attente depuis le navigateur a donc deux chunks de texte, et une image mise en file d'attente par l'API en a un :

```text
> comfy png-info output/l01/metronome_00001_.png
chunk IHDR: 1 x, 13 bytes
chunk tEXt: 1 x, 921 bytes
chunk IDAT: 23 x, 3146752 bytes once inflated
chunk IEND: 1 x, 0 bytes
text prompt: 914 characters: {"4": {"class_type": "CheckpointLoaderSimple", "inputs": {"c...
image: 1024 x 1024, 3 channels, pixel SHA-256 698e7867e7fc04fb

> comfy png-info output/l03/from-ui_00001_.png
chunk IHDR: 1 x, 13 bytes
chunk tEXt: 2 x, 4886 bytes
chunk IDAT: 23 x, 3146752 bytes once inflated
chunk IEND: 1 x, 0 bytes
text prompt: 1191 characters: {"3": {"inputs": {"seed": 42, "steps": 25, "cfg": 7.0, "samp...
text workflow: 3679 characters: {"id": "00000000-0000-0000-0000-000000000000", "revision": 0...
image: 1024 x 1024, 3 channels, pixel SHA-256 5374ac40a393cf78
```

Le lecteur C# de [`Png.cs`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Png.cs) vérifie le CRC de chaque chunk, lit les chunks `tEXt` et `iTXt`, et décode lui-même les pixels, avec `ZLibStream` et les cinq filtres de ligne du PNG, pour que l'empreinte porte sur les pixels et non sur les octets du fichier. La ligne IDAT montre pourquoi. Lors de la première exécution de la CI, la même image de 64 × 48 faisait 84 octets compressés sous Linux et 88 sous Windows et macOS : la bibliothèque zlib qu'utilise Pillow diffère très probablement d'une plateforme à l'autre. La taille décompressée, 9 264 octets, est la même partout, et les pixels aussi.

Deux mises en garde sur ces métadonnées :

- **Elles voyagent avec l'image.** Un PNG que tu publies contient ton prompt, ton prompt négatif, le nom du fichier de modèle et ta configuration de nœuds. Démarre le serveur avec `--disable-metadata`, ou retire les chunks, quand cela compte.
- **Elles ne prouvent rien.** La [page sur les métadonnées](https://docs.comfy.org/development/api-development/workflow-metadata) le dit clairement : « Embedded metadata is not a digital signature. It does not prove who created or modified a file. » Les métadonnées intégrées ne sont pas une signature numérique et ne prouvent pas qui a créé ou modifié un fichier. N'importe qui peut écrire n'importe quel prompt dans un PNG.

Le PNG mis en file d'attente depuis le navigateur montre aussi le widget de contrôle à l'œuvre. Son chunk `workflow` enregistre la graine 42, la valeur au moment où Run a été pressé ; juste après la mise en file, le frontend a remplacé la graine par 140956311522585, donc appuyer une seconde fois sur Run n'aurait pas produit la même image.

## Points clés

- Le format de l'interface décrit un dessin : des positions, des valeurs de widgets par position, et des liens stockés dans une table et sur les deux nœuds. Le format de l'API ne contient que les types de nœuds, les entrées nommées et les liens.
- La conversion a besoin des définitions de nœuds de `/object_info`, pour les noms et l'ordre des entrées, et doit sauter les valeurs de control after generate. Le convertisseur C# du cours reproduit l'export du frontend octet pour octet sur un graphe simple.
- Relis les changements de workflow sur le format de l'API, avec une comparaison qui porte sur les types de nœuds et les entrées.
- Valide hors ligne pour obtenir une liste d'erreurs complète ; le serveur s'arrête au premier problème d'un nœud, et peut répondre avec une trace d'appels.
- Les fichiers PNG contiennent le prompt, et le workflow quand l'image a été mise en file d'attente depuis le navigateur. Hache les pixels, pas les fichiers.

## Exercices

1. Ajoute un second nœud `SaveImage` à `01-txt2img.api.json`, alimenté par le nœud `VAEDecode`, avec le préfixe `l03/copy`. Exécute `comfy validate` dessus : quel ordre affiche-t-il ?
2. Dans `03-broken.api.json`, corrige tout sauf le lien vers le nœud 12, et envoie-le à un serveur en marche. Quelles erreurs le serveur signale-t-il maintenant ?
3. Le nœud 9 du fichier d'interface a `"outputs": [{"name": "images", "type": "IMAGE", "links": null}]`. `SaveImage` est un nœud de sortie ; pourquoi a-t-il une sortie ? Regarde son `RETURN_TYPES` dans [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1660-L1720) et `/object_info/SaveImage`.

<details>
<summary>Solution 1</summary>

```json
  "10": {
    "class_type": "SaveImage",
    "inputs": { "filename_prefix": "l03/copy", "images": ["8", 0] }
  }
```

`valid; the nodes can run in this order: 4 5 6 7 3 8 10 9`. La commande trie par identifiant, en tant que chaînes, les nœuds prêts au même moment, donc `10` vient avant `9`. Les deux nœuds de sortie ne dépendent que du nœud 8, donc les deux ordres sont corrects. Le serveur choisit son propre ordre, et la leçon 4 montre qu'il change d'un démarrage à l'autre.

</details>

<details>
<summary>Solution 2</summary>

Avec le checkpoint présent sur le serveur, `steps` remis à 25, `sampler_name` à `euler`, et `latent_image` à `["5", 0]`, seul `negative` pointe encore vers le nœud 12. Envoyé trois fois à un serveur qui avait le fichier SDXL dans son dossier de modèles, il a reçu la même réponse chaque fois : un HTTP 400 avec une seule entrée dans `node_errors`, pour le nœud 3, de type `exception_during_inner_validation`, avec les détails `'12'`, le nom d'entrée `samples`, et une trace d'appels de `KeyError`. Le type d'erreur décrit un échec du code de validation, pas un nœud manquant, et l'entrée qu'il nomme est celle du nœud 8, donc un client qui ne montre que `type` à ses utilisateurs devrait aussi montrer `details`.

</details>

<details>
<summary>Solution 3</summary>

`SaveImage` déclare `RETURN_TYPES = ("IMAGE",)` et sa méthode `save_images` renvoie `{"ui": {"images": results}, "result": (images,)}` : la partie `ui` est ce que le serveur envoie aux clients et stocke dans l'historique, et `result` transmet les images, pour qu'un autre nœud puisse les utiliser après l'enregistrement. `/object_info/SaveImage` montre `"output": ["IMAGE"]` et `"output_node": true`. Le frontend dessine l'emplacement de sortie ; `"links": null` signifie que rien n'y est connecté.

</details>

## Sources

- Documentation de ComfyUI : [format de l'API des workflows](https://docs.comfy.org/development/api-development/workflow-api-format), spécifications [workflow JSON 0.4](https://docs.comfy.org/specs/workflow_json_0.4) et [1.0](https://docs.comfy.org/specs/workflow_json), [métadonnées des workflows](https://docs.comfy.org/development/api-development/workflow-metadata), [SaveImage](https://docs.comfy.org/built-in-nodes/SaveImage).
- ComfyUI à la v0.36.0 : [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py), [`comfy_execution/graph_utils.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_execution/graph_utils.py#L1-L10).
- W3C, [Portable Network Graphics (PNG) Specification (Third Edition)](https://www.w3.org/TR/png-3/).
- .NET : [`System.Text.Json.Nodes`](https://learn.microsoft.com/dotnet/api/system.text.json.nodes), [`ZLibStream`](https://learn.microsoft.com/dotnet/api/system.io.compression.zlibstream).
