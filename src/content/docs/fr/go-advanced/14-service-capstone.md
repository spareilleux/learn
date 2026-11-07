---
title: "14. Un service intégré de tâches HTTP"
description: "Suivre une requête complète : validation, admission avec propriété des données, travail borné, réponse et drain."
sidebar:
  order: 14
---

## Objectif pédagogique

Suivre une requête complète : validation, admission avec propriété des données, travail borné, réponse et drain.

## Mécanismes et repères C#/Java

Ce projet final compose [net/http](https://pkg.go.dev/net/http), valeurs métier et worker borné en un service observable. Un POST sur /jobs transporte un nom et des entiers. L’adaptateur borne les octets, décode exactement un document, valide le nom et soumet une copie. Un worker calcule le total et dépose un résultat dans une réponse tamponnée. Le handler écrit le JSON ou signale l’annulation. Les garanties réelles sont traitement en mémoire, budgets finis et arrêt explicite, sans promesse de livraison durable.

Le service possède sa file et la durée de vie de son worker. Submit et Drain partagent un mutex autour de l’admission : fermer la file ne peut donc croiser un envoi. L’insertion non bloquante renvoie ErrFull plutôt que de créer une goroutine en attente indéfinie. Après le début du drain, les soumissions renvoient ErrClosed. Le worker consomme les tâches acceptées puis ferme done. Répéter Drain est sûr ; son échéance borne l’attente sans rouvrir l’admission. Cette transition d’état se teste sans sleep.

Annuler ne signifie pas défaire une somme terminée. Le worker vérifie le contexte avant de calculer ; le calcul fini peut se terminer si l’annulation arrive ensuite. Sa réponse tamponnée empêche un demandeur HTTP parti de bloquer la fin du worker. Les données copiées à l’admission ne peuvent être modifiées par l’appelant ensuite. Ces règles de propriété et de fin relient les leçons précédentes plus directement que l’ajout d’un framework ou d’une base. Persister demanderait identités, états durables et reprise hors du périmètre actuel.

La commande montre un succès, vide le service puis observe le refus d’une requête tardive. Le test d’intégration [httptest](https://pkg.go.dev/net/http/httptest) ajoute une vraie requête HTTP sur boucle locale avec un timeout client fini. Les recorders couvrent corps malformé ou excessif, champs inconnus, méthodes et chemins. Les tests de propriété des données et d’annulation isolent les causes. Services hébergés C# et endpoints Java avec exécuteurs rencontrent les mêmes cycles de vie, mais Go expose le protocole des goroutines et canaux. Examinez chaque envoi bloquant, chaque propriétaire de fermeture et chaque budget. Une suite verte établit les contrats exercés, pas l’aptitude opérationnelle ou l’acceptation pédagogique.

## Exemple complet exécutable

L’exécutable appartient au module indépendant `example.com/learn/go-advanced`. Sa commande appelle des packages réutilisables plutôt que de contenir seule le comportement. Lisez d’abord le package, puis suivez ses appels depuis la commande. Les fichiers versionnés sont reproduits entièrement : imports, chemins d’erreur et libération des ressources restent visibles. Aucun état caché de notebook ni service externe n’est requis. Les commandes emploient le même répertoire et la même syntaxe sous Windows, Linux/WSL et macOS lorsque Go figure dans PATH.

### Source réutilisable

[jobs/service.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/jobs/service.go)

```go
package jobs

import (
	"context"
	"errors"
	"example.com/learn/go-advanced/domain"
	"sync"
)

var ErrFull = errors.New("queue full")
var ErrClosed = errors.New("service closed")

type Result struct {
	Total int
	Err   error
}
type work struct {
	ctx   context.Context
	job   domain.Job
	reply chan Result
}
type Service struct {
	mu     sync.Mutex
	closed bool
	queue  chan work
	done   chan struct{}
}

func New(capacity int) *Service {
	if capacity < 0 {
		capacity = 0
	}
	s := &Service{queue: make(chan work, capacity), done: make(chan struct{})}
	go func() {
		defer close(s.done)
		for task := range s.queue {
			if err := task.ctx.Err(); err != nil {
				task.reply <- Result{Err: err}
				continue
			}
			task.reply <- Result{Total: task.job.Total()}
		}
	}()
	return s
}

func (s *Service) Submit(ctx context.Context, job domain.Job) (<-chan Result, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	owned, err := domain.NewJob(job.Name, job.Values)
	if err != nil {
		return nil, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.closed {
		return nil, ErrClosed
	}
	reply := make(chan Result, 1)
	select {
	case s.queue <- work{ctx, owned, reply}:
		return reply, nil
	default:
		return nil, ErrFull
	}
}

func (s *Service) Drain(ctx context.Context) error {
	s.mu.Lock()
	if !s.closed {
		s.closed = true
		close(s.queue)
	}
	s.mu.Unlock()
	select {
	case <-s.done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
```

[cmd/l14/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l14/main.go)

```go
package main

import (
	"context"
	"example.com/learn/go-advanced/httpapi"
	"example.com/learn/go-advanced/jobs"
	"fmt"
	"net/http/httptest"
	"strings"
)

func main() {
	service := jobs.New(2)
	defer service.Drain(context.Background())
	api := httpapi.API{Service: service}
	first := httptest.NewRecorder()
	api.ServeHTTP(first, httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"sum","values":[4,5]}`)))
	fmt.Println(first.Code)
	fmt.Print(first.Body.String())
	if err := service.Drain(context.Background()); err != nil {
		panic(err)
	}
	late := httptest.NewRecorder()
	api.ServeHTTP(late, httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"late"}`)))
	fmt.Println(late.Code)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l14
```

### Contrat de sortie attendu

```text
200
{"total":9}
503
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Le client expire après soumission. Peut-on répéter automatiquement la requête ?

<details>
<summary>Solution complète</summary>

Non. Elle peut déjà être terminée et ce service ne possède aucune identité durable de déduplication. Réconciliez l’issue avant de répéter un effet externe. L’annulation contrôle attente et coopération, sans rollback transactionnel.

</details>

2. Décrivez un test d’acceptation complet pour l’arrêt.

<details>
<summary>Solution complète</summary>

Soumettez des données valides copiées, recevez le total attendu, videz avec un contexte borné, répétez le drain, puis vérifiez ErrClosed et sa traduction HTTP 503. Ordonnez par canaux ou fin de requête, jamais par sleep.

</details>

## Sources primaires

- [net/http](https://pkg.go.dev/net/http)
- [httptest](https://pkg.go.dev/net/http/httptest)
- [context](https://pkg.go.dev/context)

[Leçon suivante](../journal/) · [Journal d’apprentissage](../journal/)
