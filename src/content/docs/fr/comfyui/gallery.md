---
title: Galerie
description: "Toutes les images rendues par ce cours, avec le modèle, la graine et le workflow qui les ont faites, et la page qu'elles illustrent — premiers rendus, la même graine deux fois, balayages d'étapes et de CFG, échecs d'inpainting, contours Canny, modèles quantifiés comparés, agrandissement et textures raccordables, et les dessins des nœuds Guitar Alchemist."
sidebar:
  order: 98
---

Toutes les images de ce cours, dans l'ordre où les leçons les rendent. Chacune garde la note écrite là où elle apparaît : la version de ComfyUI, le modèle, la graine et le workflow, de sorte que n'importe laquelle puisse être refaite. Les workflows sont dans [`code/comfyui/workflows/`](https://github.com/spareilleux/learn/tree/main/code/comfyui/workflows), et chaque lien ci-dessous pointe sur la révision exacte qui a produit l'image.

Plusieurs sont des échecs, gardés exprès. Un cours qui ne montre que ce qui a marché n'en enseigne que la moitié.

## [1. Le graphe de nœuds, l'installation et une première image](../01-install-first-image/)

![Un objet en laiton sur un vieil établi en bois, éclairé par le soleil du matin à travers une fenêtre poussiéreuse. Il ressemble plus à un sablier orné qu'à un métronome : un haut corps de verre à la taille étroite, tenu dans un cadre de laiton sur un socle rond.](../../../../assets/comfyui/l01-metronome.webp)

*Rendu par ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, graine 42, 25 étapes, sampler `euler`, scheduler `normal`, CFG 7, 1024 × 1024, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json), réduit à 768 × 768 pour cette page.*

## [2. La diffusion, et ce qui rend une image reproductible](../02-diffusion-reproducibility/)

Toutes les images ci-dessous ont été rendues par ComfyUI v0.36.0 à partir du workflow de la leçon 1 avec une seule entrée modifiée. Pour chaque image : Stable Diffusion XL base 1.0, 1024 × 1024, prompt positif « a brass metronome on an old wooden workbench, morning light through a window, dust in the air, photograph », prompt négatif « blurry, text, watermark », workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json), réduites pour cette page. Sauf mention contraire dans la légende : graine 42, 25 étapes, CFG 7, sampler `euler`, scheduler `normal`.

![Cinq rendus côte à côte. Avec 1 étape, un flou rougeâtre sombre. Avec 4 étapes, un objet conique, terne et flou, dans une pièce sombre. Avec 10 étapes, un objet en laiton net sur un établi près d'une fenêtre. Avec 25 et 50 étapes, une version plus nette de la même scène, celle à 50 étapes avec plus d'outils sur l'établi.](../../../../assets/comfyui/l02-steps.webp)

*Graine 42 ; 1, 4, 10, 25 et 50 étapes.*

![Quatre rendus côte à côte. Avec un CFG de 1, une lanterne de verre transparente et délavée dans une pièce aux couleurs passées. Avec un CFG de 3, un objet en laiton pâle dans un atelier brumeux. Avec un CFG de 7, l'objet en laiton saturé de la leçon 1. Avec un CFG de 12, une version plus contrastée avec un socle carré.](../../../../assets/comfyui/l02-cfg.webp)

*Graine 42 ; CFG 1, 3, 7 et 12.*

![Trois rendus côte à côte. euler avec normal : l'objet en laiton de la leçon 1. dpmpp_2m avec karras : une composition très semblable, avec de petites différences dans les outils. euler_ancestral : un autre objet, une pyramide en laiton sur un socle carré, devant une fenêtre ensoleillée.](../../../../assets/comfyui/l02-samplers.webp)

*Graine 42 ; `euler` avec `normal`, `dpmpp_2m` avec `karras`, `euler_ancestral` avec `normal`.*

![Quatre rendus côte à côte, tous d'un objet en laiton sur un établi près d'une fenêtre. Graine 42 : l'objet orné qui ressemble à un sablier. Graine 43 : un objet en forme de pyramide avec une graduation, plus proche d'un métronome. Graine 7 : un sablier trapu sur un socle carré, avec un rideau. La seconde image d'un lot de deux avec la graine 42 : un grand objet conique à côté d'un support en bois.](../../../../assets/comfyui/l02-seeds.webp)

*Graines 42, 43 et 7 ; puis la seconde image d'un lot de deux avec la graine 42 (`batch_size` 2).*

![Trois panneaux. Les deux premiers sont les deux rendus de graine 42, qui semblent identiques à cette taille. Le troisième est une image blanche avec des lignes sombres là où ils diffèrent, amplifiées huit fois : le contour de l'objet en laiton, son verre, les outils sur l'établi et le cadre de la fenêtre.](../../../../assets/comfyui/l02-cold-warm.webp)

*À gauche : première exécution après le démarrage du serveur. Au milieu : le même graphe exécuté de nouveau après le réencodage du prompt négatif. À droite : là où ils diffèrent, amplifié huit fois, sombre là où la différence est grande.*

## [5. Img2img, inpainting et outpainting](../05-img2img-inpainting/)

![Cinq images côte à côte. La première est la photographie de la leçon 1, un objet en laiton qui ressemble à un sablier sur un établi. Les quatre suivantes sont des versions façon aquarelle : avec un denoise de 0,3 et de 0,5, la composition est identique et le style change ; avec 0,7, la fenêtre et les outils commencent à bouger ; avec 0,9, l'objet est plus simple, les outils sont différents et la fenêtre a une nouvelle forme.](../../../../assets/comfyui/l05-img2img.webp)

*Rendu par ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, graine 42, 25 étapes, CFG 7, `euler`, `normal`, workflow [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-img2img.api.json) avec le prompt « a watercolor painting of a brass metronome on an old wooden workbench, morning light through a window ». De gauche à droite : l'image de départ, puis `denoise` 0,3, 0,5, 0,7 et 0,9.*

![Six recadrages de l'avant droit de l'établi, chacun de 340 pixels sur 240. L'original a deux petits objets en bois. VAEEncodeForInpaint : les objets ont disparu, et une ellipse pâle avec une autre texture de bois montre où était le masque. Masque de bruit avec un denoise de 1 : une bande bleuâtre uniforme et une petite tache blanche dans une ellipse visible. Masque de bruit avec un denoise de 0,8 : les deux objets sont toujours là, plus sombres et plus durs, avec un contour sombre. Modèle d'inpainting avec un denoise de 0,99 : une cloche en laiton couchée sur le côté et une pièce de bois ronde, dans la même lumière que le reste de l'établi.](../../../../assets/comfyui/l05-inpaint.webp)

*Rendu par ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, et le UNet SD-XL inpainting 0.1 pour le dernier recadrage ; graine 42, 25 étapes, CFG 7, `euler`, `normal`, prompt « a small brass bell on an old wooden workbench, morning light through a window, photograph ». De gauche à droite : l'original, [`05-inpaint-vaeencode`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json), [`05-inpaint-noisemask`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-noisemask.api.json) avec `denoise` 1 et 0,8, et [`05-inpaint-model`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json) avec `denoise` 0,99. Chaque recadrage est le résultat recollé dans l'original.*

![Une image large, de 1536 pixels sur 1024, réduite : l'objet en laiton sur son établi au milieu, avec un atelier ajouté des deux côtés : des étagères et une lampe à gauche, la fenêtre prolongée et un étau à droite.](../../../../assets/comfyui/l05-outpaint.webp)

*Rendu par ComfyUI v0.36.0 : UNet SD-XL inpainting 0.1 avec les encodeurs de texte et le VAE de SDXL base 1.0, graine 42, 25 étapes, CFG 7, `euler`, `normal`, `denoise` 0,99, workflow [`05-outpaint.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-outpaint.api.json) : 256 pixels ajoutés à gauche et à droite, fondu de 40.*

## [6. ControlNet : contours et profondeur](../06-controlnet/)

![Quatre images de 1024 pixels côte à côte. D'abord, des contours blancs sur fond noir : la silhouette de l'objet qui ressemble à un sablier, son socle, le cadre de la fenêtre et les outils sur l'établi. Ensuite, le même objet sculpté dans de la glace bleue translucide, debout sur son socle en bois, au même endroit et dans la même lumière. Puis une carte de profondeur grise : l'objet et son socle en blanc, l'établi en gris clair, la fenêtre en gris foncé. Enfin, l'objet redessiné en bois poli avec la même silhouette, entouré de petites pièces de bois.](../../../../assets/comfyui/l06-canny-depth.webp)

*Rendu par ComfyUI v0.36.0 : Stable Diffusion XL base 1.0 avec le ControlNet union SDXL ProMax de xinsir à un `strength` de 0,8, graine 42, 25 étapes, CFG 7, `euler`, `normal`. De gauche à droite : les contours de l'image de la leçon 1, `Canny` 0,4 et 0,8 ; le rendu de [`06-canny.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/06-canny.api.json), prompt « a metronome carved from blue ice on an old wooden workbench, morning light through a window, photograph » ; la carte de profondeur de Lotus ; le rendu de [`06-depth.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/06-depth.api.json), prompt « a small robot made of polished wood on an old wooden workbench, morning light through a window, photograph ».*

![Trois rendus de l'objet en glace côte à côte. Avec un strength de 0,3, l'objet a la même forme, la lumière est plus douce et les barreaux de la fenêtre sont légèrement déplacés. Avec un strength de 1,0, l'image est presque la même qu'avec 0,8. Avec un end percent de 0,3, l'image est presque la même qu'avec le ControlNet actif à chaque étape.](../../../../assets/comfyui/l06-strength.webp)

*Rendu par ComfyUI v0.36.0 : Stable Diffusion XL base 1.0 avec le ControlNet union SDXL ProMax de xinsir, graine 42, 25 étapes, CFG 7, `euler`, `normal`, workflow [`06-canny.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/06-canny.api.json). De gauche à droite : `strength` 0,3, `strength` 1,0, et `strength` 0,8 avec `end_percent` 0,3.*

## [7. LoRA : chargement, empilement, et ce qu''implique d''en entraîner un](../07-lora/)

![Trois images en pixel art côte à côte. Avec une force de 0,5, un objet en laiton détaillé qui ressemble à un sablier sur un établi, devant une fenêtre avec des arbres, en pixels fins. Avec une force de 1,0, un objet plus simple dans une pièce en bois avec des bouteilles sur une étagère, en pixels plus gros. Avec une force de 1,5, plus de métronome : une petite table avec un flacon vert, un tableau encadré et une fenêtre, en grands pixels uniformes.](../../../../assets/comfyui/l07-pixel-art.webp)

*Rendu par ComfyUI v0.36.0 : Stable Diffusion XL base 1.0 avec Pixel Art XL, graine 42, 25 étapes, CFG 7, `euler`, `normal`, prompt « pixel art, a brass metronome on an old wooden workbench, morning light through a window », workflow [`07-lora.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lora.api.json). De gauche à droite : `strength_model` et `strength_clip` à 0,5, 1,0 et 1,5.*

![Quatre images côte à côte. SDXL base avec 4 étapes : un objet conique sombre et flou devant une fenêtre. LCM-LoRA : un instrument net en laiton et en verre avec une graduation, sur un établi près d'une fenêtre. SDXL-Lightning : un objet en laiton en forme de lanterne contenant un sablier, près d'une fenêtre, net. LCM-LoRA avec Pixel Art XL : une armoire en bois en pixel art avec un tube vert dans un cadre, sur un mur de briques.](../../../../assets/comfyui/l07-few-steps.webp)

*Rendu par ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, graine 42, prompt « a brass metronome on an old wooden workbench, morning light through a window, dust in the air, photograph » pour les trois premières. De gauche à droite : [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/01-txt2img.api.json) avec 4 étapes, CFG 7, `euler`, `normal` et sans LoRA ; [`07-lcm.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lcm.api.json), LCM-LoRA, 4 étapes, CFG 1, `lcm`, `sgm_uniform` ; [`07-lightning.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lightning.api.json), LoRA SDXL-Lightning 4-step, 4 étapes, CFG 1, `euler`, `sgm_uniform` ; [`07-lora-stack.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lora-stack.api.json), LCM-LoRA à 1,0 et Pixel Art XL à 1,2, 8 étapes, CFG 1,5, `lcm`, `sgm_uniform`, prompt « pixel art, a brass metronome on an old wooden workbench, morning light through a window ».*

## [8. Modèles récents et leurs licences, quantification et VRAM](../08-recent-models-quantization/)

![Quatre rendus côte à côte, chacun un métronome pyramidal doré et noir sur un établi en bois usé devant une fenêtre. bf16 et int8 : presque la même image, avec un appareil à interrupteurs à gauche. nvfp4 avec l'encodeur de texte fp4 : le même genre de scène, avec le métronome un peu plus grand, et des livres et un bocal sur l'établi. nvfp4 avec l'encodeur de texte bf16 : proche du précédent, avec les objets disposés autrement.](../../../../assets/comfyui/l08-quantized.webp)

*Rendu par ComfyUI v0.36.0 : Z-Image-Turbo, graine 42, 8 étapes, CFG 1, `res_multistep`, `simple`, shift 3, prompt « a brass metronome on an old wooden workbench, morning light through a window, dust in the air, photograph », workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). De gauche à droite : réseau bf16 avec l'encodeur de texte bf16 ; int8 convrot avec fp8 mixed ; nvfp4 avec fp4 mixed ; nvfp4 avec bf16.*

![Quatre rendus côte à côte. D'abord, le rendu bf16 de Z-Image-Turbo avec la graine 43 : un métronome pyramidal sur un établi. Puis trois rendus de FLUX.2 klein 4B avec les graines 42, 43 et 44 : chacun un atelier poussiéreux avec une fenêtre et un objet en laiton sur un établi usé, mais l'objet est un support avec une manivelle ou des bras, pas un métronome.](../../../../assets/comfyui/l08-z-image-klein.webp)

*Rendu par ComfyUI v0.36.0. D'abord : Z-Image-Turbo bf16, graine 43, réglages comme ci-dessus. Ensuite : FLUX.2 klein 4B distillé, bf16, avec l'encodeur de texte Qwen3 4B, graines 42, 43 et 44, 4 étapes, CFG 1, `euler`, `Flux2Scheduler`, même prompt, workflow [`08-flux2-klein.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-flux2-klein.api.json).*

## [9. Agrandissement, textures raccordables et HDR](../09-upscaling-seamless-hdr/)

![Trois recadrages de 512 × 512 du même manche de guitare devant un mur de briques, agrandis quatre fois. Nearest : des blocs carrés de quatre pixels sur les cordes et les frettes. Lanczos : lisse mais flou, avec de légers halos le long des frettes. Real-ESRGAN : des frettes et des cordes nettes, une brique plus plate, et le fil des frettes dessiné en lignes claires et propres.](../../../../assets/comfyui/l09-upscale-methods.webp)

*Rendu par ComfyUI v0.36.0 : le détail en (384, 384) du premier rendu de la section suivante, agrandi 4 × avec `ImageScaleBy` `nearest-exact`, `ImageScaleBy` `lanczos`, et `ImageUpscaleWithModel` avec `RealESRGAN_x4plus.safetensors`, workflow [`09-upscale-model.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-upscale-model.api.json). Chaque panneau montre les 512 × 512 pixels du milieu du résultat de 1024 × 1024, à l'échelle 1:1.*

![Quatre panneaux. D'abord, le rendu entier de 1024 × 1024 : une guitare acoustique appuyée contre un mur de briques à côté d'une vitrine avec d'autres guitares. Puis le même recadrage de 512 × 512 de trois versions en 2048 × 2048 : Lanczos, flou ; Real-ESRGAN, des cordes et des briques nettes ; hires fix, avec un nouveau veinage du bois, une nouvelle texture de brique et les repères de frettes déplacés.](../../../../assets/comfyui/l09-hires-fix.webp)

*Rendu par ComfyUI v0.36.0 : Z-Image-Turbo nvfp4 avec Qwen3 4B fp4 mixed, graine 42, 8 étapes, CFG 1, `res_multistep`, `simple`, shift 3, prompt « an acoustic guitar leaning against a brick wall in a small music shop, warm evening light, photograph », workflow [`09-hires-fix.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-hires-fix.api.json). De gauche à droite : la première passe ; le recadrage de (768, 768) à (1280, 1280) de Lanczos 2 ×, de Real-ESRGAN puis Lanczos 0,5, et du hires fix avec un denoise de 0,33 et la graine 42.*

![Quatre recadrages de 512 × 512 de la tête et du manche de la guitare devant le mur de briques, après le hires fix avec un denoise de 0,2, 0,33, 0,5 et 0,7. À 0,2, l'image est l'image agrandie avec un peu plus de texture. À 0,33, les briques gagnent du grain. À 0,5, les joints de mortier et les taches des briques changent. À 0,7, la tête est redessinée avec d'autres mécaniques, et le manche est plus étroit.](../../../../assets/comfyui/l09-hires-denoise.webp)

*Rendu par ComfyUI v0.36.0 : le même workflow et la même première passe, deuxième passe avec un denoise de 0,2, 0,33, 0,5 et 0,7, recadrage de (768, 256) à (1280, 768).*

![Trois recadrages de 512 × 512 de la même tête et du même manche après un agrandissement latent et une deuxième passe avec un denoise de 0,3, 0,55 et 0,75. À 0,3, l'image est couverte d'un grain fin et bruité, et les cordes sont dédoublées. À 0,55, elle est propre, avec la brique redessinée. À 0,75, la tête et les repères de frettes sont redessinés.](../../../../assets/comfyui/l09-latent-denoise.webp)

*Rendu par ComfyUI v0.36.0 : Z-Image-Turbo nvfp4, même première passe, `LatentUpscaleBy` `bislerp` 2 ×, deuxième `KSampler` avec 8 étapes, `res_multistep`, `simple`, denoise de 0,3, 0,55 et 0,75, workflow [`09-latent-upscale.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-latent-upscale.api.json).*

![Quatre panneaux de 384 × 384. Une texture de palissandre au veinage vertical. La même texture décalée de moitié, avec un raccord horizontal et vertical visible au milieu. Un carré noir avec une croix blanche, douce sur ses bords. Le résultat, où le milieu montre un veinage continu et aucune ligne nette.](../../../../assets/comfyui/l09-seamless-steps.webp)

*Rendu par ComfyUI v0.36.0 : Z-Image-Turbo int8 convrot avec Qwen3 4B fp8 mixed, graine 42 pour les deux passes, 8 étapes, CFG 1, `res_multistep`, `simple`, prompt « flat top-down photograph of dark rosewood, fine straight grain, even soft lighting, no shadows, wood texture », une photographie à plat, vue de dessus, de palissandre sombre au veinage fin et droit, workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json). De gauche à droite : le rendu, le décalage, le masque, le résultat.*

![Quatre aperçus en mosaïque, chacun une répétition en 2 × 2. Le palissandre tel que rendu : une grille nette de raccords durs. Le palissandre après la réparation : aucun raccord dur, avec des blocs un peu plus sombres et plus clairs encore visibles. L'érable pâle tel que rendu : une grille de raccords. L'érable après la réparation : aucun raccord dur, avec de douces bandes verticales de bois plus clair et plus sombre.](../../../../assets/comfyui/l09-seamless.webp)

*Rendu par ComfyUI v0.36.0 : le même workflow et le même modèle. De gauche à droite : le palissandre tel que rendu, puis réparé ; l'érable, prompt « flat top-down photograph of pale maple wood, a planed board with fine straight grain, even soft lighting, wood texture », tel que rendu, puis réparé. Chaque panneau est une répétition de 2048 × 2048 affichée en 512 × 512.*

## [11. Les nœuds personnalisés, et leur sécurité](../11-custom-nodes-and-security/)

![Six diagrammes d'accords alignés, noir sur blanc, la corde de mi grave à gauche et le sillet en haut. Do : une croix au-dessus de la corde 6, des points sur la case 3 de la corde 5, la case 2 de la corde 4 et la case 1 de la corde 2, des cercles au-dessus des cordes 3 et 1. Sol : des points sur la case 3 des cordes 6 et 1 et sur la case 2 de la corde 5, trois cordes à vide. La mineur : une croix, puis des points sur la case 2 des cordes 4 et 3 et sur la case 1 de la corde 2. Fa : des points sur la case 1 des cordes 6, 2 et 1, sur la case 3 des cordes 5 et 4, et sur la case 2 de la corde 3. Mi sept : des points sur la case 2 de la corde 5 et sur la case 1 de la corde 3, quatre cordes à vide. Si mineur sept bémol cinq : des croix au-dessus des cordes 6 et 1, des points sur les cases 2, 3, 2 et 3 des cordes 5 à 2.](../../../../assets/comfyui/l11-chord-diagrams.webp)

*Dessinés par le nœud GA Chord Diagram avec Pillow, pas par un modèle de diffusion : `C`, `G`, `Am`, `F`, `E7` et `Bm7b5`, 256 pixels chacun, les images de [`expected/`](https://github.com/spareilleux/learn/tree/22f2bf71c21d2cc4f426c0e917e7e19dbfca5bc3/code/comfyui/custom-nodes/ga/expected).*

![Deux cartes du manche, l'une au-dessus de l'autre. En haut, des lignes blanches sur fond noir : le manche du sillet à la case 5, six cordes, un sillet épais à gauche, deux petits repères ronds, et l'accord de do majeur sous forme d'anneaux blancs : case 3 sur la corde de la, case 2 sur la corde de ré, case 1 sur la corde de si, et deux anneaux à gauche du sillet pour les cordes de sol et de mi aigu à vide. En bas, la version en profondeur de la éolien de la case 5 à la case 12 : une touche grise, des cordes et des frettes plus claires, et des points blancs sur chaque note de la gamme de la mineur.](../../../../assets/comfyui/l11-control-maps.webp)

*Dessinées par le nœud GA Fretboard Control Map avec Pillow : la sortie `lines` pour l'accord `C`, cases 0 à 5, et la sortie `depth` pour la éolien, cases 5 à 12 ; toutes deux en 1024 × 1024, recadrées autour du manche et réduites.*

## [Journal](../journal/)

![Un objet en laiton sur un vieil établi en bois, éclairé par le soleil du matin à travers une fenêtre poussiéreuse. Il ressemble plus à un sablier ouvragé qu'à un métronome : un haut corps de verre à la taille étroite, tenu dans un cadre en laiton sur un socle rond.](../../../../assets/comfyui/l01-metronome.webp)

*Le premier rendu. ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, graine 42, 25 étapes, `euler`, `normal`, CFG 7, 1024 × 1024, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json).*

![Trois panneaux. Les deux premiers sont les deux rendus de graine 42, qui paraissent identiques à cette taille. Le troisième est une image blanche avec des traits sombres là où ils diffèrent, amplifiés huit fois : le contour de l'objet en laiton, son verre, les outils sur l'établi et le cadre de la fenêtre.](../../../../assets/comfyui/l02-cold-warm.webp)

*Les deux images de graine 42. ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, graine 42, 25 étapes, `euler`, `normal`, CFG 7, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json). À gauche : première exécution après le démarrage du serveur. Au milieu : le même graphe après un nouvel encodage du prompt négatif. À droite : là où elles diffèrent, amplifié huit fois.*

![Trois recadrages de l'avant de l'établi. Le premier : une ellipse grise uniforme avec un léger ombrage là où étaient les objets. Le deuxième : une ellipse nette de bois pâle et rugueux, avec un bord sombre le long de son haut. Le troisième : deux nouveaux objets en bois sur l'établi, sans bord visible.](../../../../assets/comfyui/journal-l05-failures.webp)

*Deux échecs d'inpainting et la correction, avant de recoller le résultat. ComfyUI v0.36.0 : Stable Diffusion XL base 1.0, graine 42, 25 étapes, CFG 7, `euler`, `normal`. De gauche à droite : [`05-inpaint-vaeencode.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json) avec `denoise` 0,5 ; le même workflow avec `denoise` 1 et un masque au bord adouci sur 24 pixels ; [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json), le UNet SD-XL inpainting 0.1 avec `denoise` 0,99, sur le même masque adouci.*

![Des lignes de contour blanches sur fond noir, dessinées en gros pixels : un nid d'abeilles de cellules ondulées tiré de la mire de test du cours.](../../../../assets/comfyui/journal-canny-ci.webp)

*La sortie du nœud `Canny` sur la machine de l'auteur, hachage de pixels `77af5cb1b7e93a5c`, 464 pixels de contour, agrandie quatre fois sans lissage. ComfyUI v0.36.0 sur le CPU, sans modèle, seuils 0,05 et 0,15, workflow [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json). Les trois runners de la CI ont chacun dessiné 467 pixels de contour, avec trois autres hachages.*

![Quatre rendus côte à côte, chacun un métronome pyramidal or et noir sur un établi en bois usé devant une fenêtre. Les deux premiers sont presque identiques ; les deux derniers montrent la même scène avec les objets disposés autrement.](../../../../assets/comfyui/l08-quantized.webp)

*ComfyUI v0.36.0 : Z-Image-Turbo, graine 42, 8 étapes, CFG 1, `res_multistep`, `simple`, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). De gauche à droite : bf16 avec l'encodeur de texte bf16, int8 avec fp8, nvfp4 avec fp4, nvfp4 avec bf16.*

![Quatre rendus côte à côte. D'abord, le métronome pyramidal de Z-Image-Turbo sur un établi. Puis trois rendus d'un atelier poussiéreux par FLUX.2 klein 4B, chacun avec, au lieu d'un métronome, un support en laiton muni d'une manivelle ou de bras sur un établi usé.](../../../../assets/comfyui/l08-z-image-klein.webp)

*ComfyUI v0.36.0. D'abord : Z-Image-Turbo bf16, graine 43, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). Ensuite : FLUX.2 klein 4B, graines 42, 43 et 44, 4 étapes, CFG 1, `euler`, workflow [`08-flux2-klein.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-flux2-klein.api.json).*

![Trois panneaux. Une répétition 2 × 2 d'une texture de palissandre, avec de légères lignes horizontales et verticales à travers chaque tuile. Un recadrage du milieu de cette texture, où une rangée de mouchetures sombres traverse le fil du bois et où la moitié inférieure est plus claire. Une répétition 2 × 2 d'un bois pâle avec une grande feuille d'érable sculptée dans chaque tuile.](../../../../assets/comfyui/journal-l09-seamless-failures.webp)

*Les échecs, avant la correction. ComfyUI v0.36.0 : Z-Image-Turbo nvfp4 avec Qwen3 4B fp4 mixed, graine 42, 8 étapes, CFG 1, `res_multistep`, `simple`, workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json) avec sa croix réglée à 160 pixels, 64 de fondu et un denoise de 0,7. De gauche à droite : le palissandre répété 2 × 2 ; les 512 × 512 pixels du milieu du palissandre ; le prompt « flat top-down photograph of pale maple, subtle straight grain, even soft lighting, no shadows, wood texture » (photo à plat, vue de dessus, d'érable pâle au fil fin et droit, sous un éclairage doux et uniforme, sans ombres, texture de bois), répété 2 × 2.*
