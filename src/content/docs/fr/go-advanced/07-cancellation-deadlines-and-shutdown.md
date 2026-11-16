---
title: "7. Annulation, échéances et arrêt"
description: "Distinguer demande d’annulation, observation de fin et traitement des tâches déjà acceptées."
sidebar:
  order: 7
---

## Objectif pédagogique

Distinguer demande d’annulation, observation de fin et traitement des tâches déjà acceptées.

## Mécanismes et repères C#/Java

Un [context](https://pkg.go.dev/context) porte annulation, échéance et valeurs liées à une requête. Passez-le explicitement en premier paramètre lorsqu’une opération peut bloquer. La fonction d’annulation demande un arrêt coopératif ; elle n’attend pas les goroutines. L’exemple utilise donc deux signaux distincts : started prouve que le worker a atteint son attente, et done renvoie son erreur finale. Aucun sleep ne devine son démarrage. WithCancelCause préserve la raison sans modifier l’identité d’annulation ordinaire renvoyée par Err.

Appelez toujours la fonction d’annulation d’un contexte dérivé pour libérer ses ressources, même après une fin anticipée. La propagation des échéances empêche un enfant de prolonger son parent. Un timeout autour d’une fonction ne peut interrompre une boucle CPU arbitraire ou une bibliothèque ignorant le contexte. Placez les observations là où elles ont un sens et documentez les opérations qui se terminent une fois admises. Notre petite somme peut finir lorsqu’annulation et envoi se croisent ; une requête HTTP annulée n’implique aucun rollback.

Le service distingue admission et drain. Submit garde un mutex pendant la vérification du drapeau closed et l’envoi non bloquant dans la file. Drain utilise le même mutex pour arrêter l’admission et fermer la file. Cela évite une course entre envoi et fermeture. Le canal done ferme après consommation des tâches acceptées. Chaque réponse possède un emplacement tamponné : le worker peut terminer même si le demandeur n’attend plus. Ce canal transporte exactement un résultat ; il ne faut pas le parcourir comme un flux sans fin.

Les tokens d’annulation C# exigent eux aussi de coopérer ; annuler une future Java ne garantit pas une interruption universelle. Construisez l’arrêt autour d’états observables. Un processus HTTP arrête l’admission, laisse les handlers finir avec un contexte borné, vide les tâches acceptées puis respecte une échéance globale. [http.Server.Shutdown](https://pkg.go.dev/net/http#Server.Shutdown) gère les connexions HTTP, mais ignore le worker applicatif indépendant. L’expiration d’un drain met fin à l’attente sans rouvrir l’admission ni annuler secrètement les tâches acceptées.

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

[cmd/l07/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l07/main.go)

```go
package main

import (
	"context"
	"errors"
	"example.com/learn/go-advanced/pipeline"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancelCause(context.Background())
	defer cancel(nil)
	started := make(chan struct{})
	done := make(chan error, 1)
	go func() { done <- pipeline.Wait(ctx, started) }()
	<-started
	cancel(errors.New("requested"))
	fmt.Println(<-done)
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l07
```

### Contrat de sortie attendu

```text
requested
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Pourquoi une réponse tamponnée évite-t-elle ici une fuite pendant l’arrêt ?

<details>
<summary>Solution complète</summary>

Chaque tâche acceptée produit un seul résultat. Un emplacement permet l’envoi même si son demandeur a annulé. Sans tampon, il faudrait sélectionner l’annulation ou garantir un receveur.

</details>

2. Après une erreur d’échéance de Drain, Submit peut-il accepter de nouveau ?

<details>
<summary>Solution complète</summary>

Non. L’admission ferme une seule fois et reste fermée. L’échéance borne l’attente, sans inverser la transition du service. Rappelez Drain pour observer la fin, sans resoumettre une tâche d’issue inconnue.

</details>

## Sources primaires

- [context](https://pkg.go.dev/context)
- [http.Server.Shutdown](https://pkg.go.dev/net/http#Server.Shutdown)

[Leçon suivante](../08-production-http/) · [Journal d’apprentissage](../journal/)
