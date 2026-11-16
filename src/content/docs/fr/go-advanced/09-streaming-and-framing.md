---
title: "9. Flux et délimitation des messages"
description: "Implémenter un protocole de trames borné qui respecte lectures et écritures partielles."
sidebar:
  order: 9
---

## Objectif pédagogique

Implémenter un protocole de trames borné qui respecte lectures et écritures partielles.

## Mécanismes et repères C#/Java

Les interfaces [io](https://pkg.go.dev/io) décrivent des flux, pas une livraison de messages. Un Read peut renvoyer moins d’octets que demandé sans signifier que le pair a envoyé tout son message. Une écriture TCP n’est pas conservée comme une lecture TCP correspondante. Le même problème existe avec les tampons de fichiers et les couches de compression. Définissez le tramage avant d’interpréter un flux comme des messages. Ici, une longueur non signée sur quatre octets en ordre big endian précède le contenu.

Le package [encoding/binary](https://pkg.go.dev/encoding/binary) explicite la représentation de l’en-tête, indépendamment de l’ordre natif de la machine. Read utilise io.ReadFull pour en-tête et contenu. Il compare la longueur à MaxFrame avant d’allouer, rejetant tôt une taille hostile. Une longueur nulle représente un message vide valide. La fin avant un nouvel en-tête diffère d’une troncature au milieu d’un en-tête ou du contenu : un EOF propre peut indiquer une fermeture normale, alors qu’un EOF inattendu signale une trame endommagée.

Write vérifie la même limite, écrit l’en-tête complet puis le contenu. Son auxiliaire poursuit les écritures partielles, renvoie l’erreur du writer et refuse une écriture sans progrès. Sans ce dernier contrôle, un writer défectueux pourrait provoquer une boucle infinie. Une erreur après quelques octets ne signifie pas que rien n’a été transmis. Réessayer automatiquement sur la même connexion peut ajouter un nouvel en-tête à une trame partielle corrompue. Réconciliez l’état du protocole ou fermez le flux avant de décider si l’opération applicative peut être rejouée.

Les streams C# et Java permettent aussi des lectures partielles ; les commodités des tampons ne transforment pas une connexion en bus de messages. Le test [net.Pipe](https://pkg.go.dev/net#Pipe) relie deux extrémités locales, échange deux trames puis vérifie EOF. Ses échéances bornent les échecs, sans synchroniser par sleep. En-tête incomplet, longueur excessive et contenu tronqué précisent les échecs. Le fuzzing vérifie les allers-retours des contenus bornés. Authentification, négociation de compression et livraison durable restent hors de ce contrat.

## Exemple complet exécutable

L’exécutable appartient au module indépendant `example.com/learn/go-advanced`. Sa commande appelle des packages réutilisables plutôt que de contenir seule le comportement. Lisez d’abord le package, puis suivez ses appels depuis la commande. Les fichiers versionnés sont reproduits entièrement : imports, chemins d’erreur et libération des ressources restent visibles. Aucun état caché de notebook ni service externe n’est requis. Les commandes emploient le même répertoire et la même syntaxe sous Windows, Linux/WSL et macOS lorsque Go figure dans PATH.

### Source réutilisable

[framing/frame.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/framing/frame.go)

```go
package framing

import (
	"encoding/binary"
	"errors"
	"io"
)

const MaxFrame = 1024

var ErrTooLarge = errors.New("frame too large")

func Write(w io.Writer, payload []byte) error {
	if len(payload) > MaxFrame {
		return ErrTooLarge
	}
	var header [4]byte
	binary.BigEndian.PutUint32(header[:], uint32(len(payload)))
	if err := writeAll(w, header[:]); err != nil {
		return err
	}
	return writeAll(w, payload)
}
func writeAll(w io.Writer, data []byte) error {
	for len(data) > 0 {
		n, err := w.Write(data)
		if n < 0 || n > len(data) {
			return io.ErrShortWrite
		}
		data = data[n:]
		if err != nil {
			return err
		}
		if n == 0 {
			return io.ErrShortWrite
		}
	}
	return nil
}
func Read(r io.Reader) ([]byte, error) {
	var header [4]byte
	if _, err := io.ReadFull(r, header[:]); err != nil {
		return nil, err
	}
	size := binary.BigEndian.Uint32(header[:])
	if size > MaxFrame {
		return nil, ErrTooLarge
	}
	data := make([]byte, int(size))
	_, err := io.ReadFull(r, data)
	if err == io.EOF {
		err = io.ErrUnexpectedEOF
	}
	return data, err
}
```

[cmd/l09/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l09/main.go)

```go
package main

import (
	"bytes"
	"example.com/learn/go-advanced/framing"
	"fmt"
)

func main() {
	var wire bytes.Buffer
	if err := framing.Write(&wire, []byte("Go")); err != nil {
		panic(err)
	}
	payload, err := framing.Read(&wire)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(payload))
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l09
```

### Contrat de sortie attendu

```text
Go
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Où faut-il vérifier la limite de longueur ?

<details>
<summary>Solution complète</summary>

Juste après lecture de l’en-tête fixe et avant allocation du contenu. Vérifier après allocation consommerait déjà la mémoire excessive. Read et Write doivent partager la même limite.

</details>

2. Peut-on rejouer aveuglément une écriture de trame partiellement échouée ?

<details>
<summary>Solution complète</summary>

Non. Des octets peuvent déjà être transmis et le pair peut avoir agi. Fermez ou réconciliez le flux, puis utilisez une identité applicative et un contrat de livraison si nécessaire. Le tramage ne garantit aucune exécution unique.

</details>

## Sources primaires

- [io](https://pkg.go.dev/io)
- [encoding/binary](https://pkg.go.dev/encoding/binary)
- [net.Pipe](https://pkg.go.dev/net#Pipe)

[Leçon suivante](../10-race-fuzz-and-property-tests/) · [Journal d’apprentissage](../journal/)
