---
title: "8. Frontières HTTP en production"
description: "Définir les budgets de ressources HTTP et tester les requêtes malformées sans service externe."
sidebar:
  order: 8
---

## Objectif pédagogique

Définir les budgets de ressources HTTP et tester les requêtes malformées sans service externe.

## Mécanismes et repères C#/Java

Le package [net/http](https://pkg.go.dev/net/http) fournit rapidement un serveur fonctionnel, mais ses valeurs par défaut ne définissent pas une politique de ressources de production. Notre constructeur Server fixe des délais finis pour en-têtes, lecture, écriture et inactivité ainsi qu’une taille maximale d’en-têtes. Le handler borne séparément le corps avec MaxBytesReader et accorde une seconde au travail admis. Ces budgets sont distincts. Une échéance de handler n’impose pas à elle seule un délai de lecture de socket, et le délai d’en-tête ne limite pas le corps.

La frontière accepte POST sur /jobs, décode une valeur JSON, refuse les champs inconnus et vérifie qu’un second décodage rencontre la fin d’entrée. Sans cela, un objet valide suivi d’un autre document pourrait être accepté silencieusement. Un corps trop grand donne 413 ; une entrée malformée 400 ; une mauvaise méthode 405 avec Allow ; un service fermé ou saturé 503. L’exemple somme de petits entiers : il ne définit ni file durable ni authentification. Identité et persistance demanderaient des contrats distincts.

[httptest](https://pkg.go.dev/net/http/httptest) propose des tests par recorder en processus et un vrai serveur sur boucle locale. Les premiers isolent la traduction des requêtes ; le test d’intégration ajoute client et transport réels avec un timeout fini. Fermez les corps de réponse pour réutiliser connexions et ressources. La commande utilise un recorder pour produire une sortie déterministe sans port public. Une application réelle construit explicitement son serveur et coordonne son arrêt avec celui du worker.

Les middlewares C# et filtres de servlets Java sont des adaptateurs connus, mais les handlers Go restent des valeurs implémentant une interface. Évitez d’utiliser le registre global comme conteneur implicite de dépendances. Injectez directement le service dans API. Après l’écriture des en-têtes, une erreur ultérieure ne peut remplacer le statut envoyé. Une observabilité de production devrait consigner les erreurs d’écriture et l’identité de requête selon une politique de confidentialité définie ; cet adaptateur minimal revient après l’échec d’encodage. Les délais bornent les ressources sans garantir l’interruption immédiate de tout calcul à la déconnexion.

## Exemple complet exécutable

L’exécutable appartient au module indépendant `example.com/learn/go-advanced`. Sa commande appelle des packages réutilisables plutôt que de contenir seule le comportement. Lisez d’abord le package, puis suivez ses appels depuis la commande. Les fichiers versionnés sont reproduits entièrement : imports, chemins d’erreur et libération des ressources restent visibles. Aucun état caché de notebook ni service externe n’est requis. Les commandes emploient le même répertoire et la même syntaxe sous Windows, Linux/WSL et macOS lorsque Go figure dans PATH.

### Source réutilisable

[httpapi/api.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/httpapi/api.go)

```go
package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"example.com/learn/go-advanced/domain"
	"example.com/learn/go-advanced/jobs"
	"io"
	"net/http"
	"time"
)

const MaxBody = 256

type API struct{ Service *jobs.Service }

func (a API) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/jobs" {
		http.NotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		w.Header().Set("Allow", http.MethodPost)
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), time.Second)
	defer cancel()
	r.Body = http.MaxBytesReader(w, r.Body, MaxBody)
	defer r.Body.Close()
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	var input struct {
		Name   string `json:"name"`
		Values []int  `json:"values"`
	}
	if err := decoder.Decode(&input); err != nil {
		var large *http.MaxBytesError
		if errors.As(err, &large) {
			http.Error(w, "body", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "json", http.StatusBadRequest)
		}
		return
	}
	if err := decoder.Decode(new(any)); err != io.EOF {
		var large *http.MaxBytesError
		if errors.As(err, &large) {
			http.Error(w, "body", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "trailing", http.StatusBadRequest)
		}
		return
	}
	job, err := domain.NewJob(input.Name, input.Values)
	if err != nil {
		http.Error(w, "job", http.StatusBadRequest)
		return
	}
	reply, err := a.Service.Submit(ctx, job)
	if err != nil {
		status := http.StatusServiceUnavailable
		if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			status = http.StatusRequestTimeout
		}
		http.Error(w, "unavailable", status)
		return
	}
	select {
	case result := <-reply:
		if result.Err != nil {
			http.Error(w, "cancelled", http.StatusRequestTimeout)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(struct {
			Total int `json:"total"`
		}{result.Total}); err != nil {
			return
		}
	case <-ctx.Done():
		http.Error(w, "deadline", http.StatusGatewayTimeout)
	}
}

func Server(address string, handler http.Handler) *http.Server {
	return &http.Server{Addr: address, Handler: handler, ReadHeaderTimeout: 2 * time.Second, ReadTimeout: 3 * time.Second, WriteTimeout: 3 * time.Second, IdleTimeout: 30 * time.Second, MaxHeaderBytes: 8192}
}
```

[cmd/l08/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l08/main.go)

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
	service := jobs.New(1)
	defer service.Drain(context.Background())
	request := httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"sum","values":[2,3]}`))
	response := httptest.NewRecorder()
	httpapi.API{Service: service}.ServeHTTP(response, request)
	fmt.Println(response.Code)
	fmt.Print(response.Body.String())
}
```

Depuis la racine du dépôt:

```sh
cd code/go-advanced
go run ./cmd/l08
```

### Contrat de sortie attendu

```text
200
{"total":5}
```

## Lire le contrat avant de modifier le code

Avant l’exécution, prédisez le résultat et repérez l’opération rendant chaque valeur observable. Suivez l’entrée depuis son appelant, à travers copies et références, jusqu’au consommateur final. Distinguez la valeur renvoyée par une fonction de la durée de vie des tâches qu’elle lance. Lorsqu’une erreur est possible, identifiez qui décide de s’arrêter, de réessayer ou de la traduire. Afficher une valeur de succès ne représente qu’une partie du contrat : les entrées rejetées et la terminaison doivent aussi rester compréhensibles.

Le listing est volontairement complet. Gardez-le à côté du test correspondant et nommez l’assertion précise qui échouerait après une rupture de comportement. Une modification purement interne devrait préserver ces assertions observables. Si elle change une frontière publique, décrivez d’abord la garantie modifiée. Cette habitude se transpose bien depuis C# et Java tout en gardant explicites les règles Go de propriété des données et de synchronisation.

## Vérification et périmètre

La sortie présentée constitue le contrat attendu de l’exécutable, conservé dans `examples.json`. Rejouez-le avant d’en faire une observation sur votre machine. Les tests sont écrits dans le même module ; la vérification centrale consigne séparément leur exécution réelle. Des exemples réussis ne prouvent ni tous les systèmes, ni une charge de production, ni la réussite pédagogique. Diagnostics, profils et benchmarks décrivent des expériences tant que le journal ne contient pas de mesure. Conservez ensemble version, révision et commande : sans conditions, une observation est difficile à reproduire.

## Exercices

1. Pourquoi décoder une deuxième fois après un objet valide ?

<details>
<summary>Solution complète</summary>

La frontière promet exactement un document JSON. Le second décodage doit renvoyer io.EOF ; un autre objet ou des octets invalides rompent ce contrat. Les tests locaux couvrent les objets concaténés.

</details>

2. Un contexte d’une seconde remplace-t-il MaxBytesReader et les délais du serveur ?

<details>
<summary>Solution complète</summary>

Non. Chaque mécanisme borne une ressource distincte : durée du travail, octets lus et opérations de connexion. Gardez des budgets explicites et testez séparément le rejet du corps et l’annulation.

</details>

## Sources primaires

- [net/http](https://pkg.go.dev/net/http)
- [httptest](https://pkg.go.dev/net/http/httptest)

[Leçon suivante](../09-streaming-and-framing/) · [Journal d’apprentissage](../journal/)
