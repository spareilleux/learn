---
title: "12. HTTP et context"
description: "Exercer un gestionnaire HTTP en mémoire et propager une annulation coopérative."
sidebar:
  order: 12
---

## Objectifs

Lire un contrat de gestionnaire HTTP, tester statut et JSON sans service public et identifier le propriétaire de l’annulation.

## HTTP adapte un comportement typé

Un [http.Handler](https://pkg.go.dev/net/http#Handler) traite une requête en écrivant en-têtes, statut et corps dans [`ResponseWriter`](https://pkg.go.dev/net/http#ResponseWriter). Notre package webapi expose les données d’étude par une route GET avec [http.ServeMux](https://pkg.go.dev/net/http#ServeMux). Le gestionnaire encode des valeurs typées plutôt que de fabriquer du JSON par concaténation. Il définit Content-Type avant le corps : la première écriture peut déjà valider les en-têtes.

Cette petite frontière sert à comprendre le protocole. Le CLI n’appelle pas HTTP pour employer ses propres fonctions métier ; les deux frontières utilisent study directement. On évite ainsi un réseau inutile dans un rapport local. Un gestionnaire réutilise le cœur sans devenir propriétaire de toute sa logique. Le cours avancé développera le cycle de vie des services et les préoccupations de production.

## Tester sans service extérieur

L’exemple crée un [httptest.ResponseRecorder](https://pkg.go.dev/net/http/httptest#ResponseRecorder) et une requête, puis appelle directement ServeHTTP. Aucun socket n’est ouvert, aucun service public n’est contacté. Statut, en-têtes et corps sont observables par le test. Décodez le corps en Record et vérifiez les données métier plutôt que les espaces accessoires du JSON.

Les données doivent produire un statut deux cents et deux enregistrements. Les tests vérifient aussi le type de contenu et une méthode non autorisée. Un recorder ne démontre ni configuration TLS, ni comportement de proxy, ni délimitation réseau, ni délais d’un vrai client. Cela exige d’autres tests. Limiter la conclusion au gestionnaire donne une preuve précise tout en exerçant routage, sérialisation et composition de données réels.

## Context transmet une durée de vie

Un [context.Context](https://pkg.go.dev/context#Context) transmet annulation et échéances dans une chaîne d’appels. Utilisez le contexte de la requête quand le travail lui appartient. [context.WithCancel](https://pkg.go.dev/context#WithCancel) renvoie un contexte enfant et une fonction d’annulation ; son créateur doit appeler cancel pour libérer les ressources associées. Fournir un contexte ne force pas l’arrêt d’une opération : elle doit vérifier son erreur ou sélectionner son canal Done.

Après l’appel HTTP réussi, la commande annule le contexte puis appelle Count. Count vérifie l’annulation avant de commencer et renvoie [`context.Canceled`](https://pkg.go.dev/context#Canceled), reconnu par [`errors.Is`](https://pkg.go.dev/errors#Is). L’ordre est déterministe : l’annulation précède l’appel, sans course temporelle ni pause. Le gestionnaire vérifie lui aussi le contexte avant d’encoder, et son test s’assure qu’aucun corps n’est écrit si la requête est déjà annulée.

## Comparer les durées de requête

[C# CancellationToken](https://learn.microsoft.com/dotnet/api/system.threading.cancellationtoken) aide à comprendre l’annulation coopérative, mais un contexte Go transporte aussi échéances et valeurs propres à une requête. N’y cachez pas la configuration ordinaire ni les arguments facultatifs pour éviter des paramètres explicites. Un contexte annulé ne convient pas à une nouvelle opération indépendante. Dérivez une nouvelle durée de vie du parent approprié.

L’encodage peut échouer après validation des en-têtes. Notre petit gestionnaire retourne alors ; il ne définit pas une politique complète de diagnostic ou de mise en tampon de production. Un contrôle initial d’annulation ne garantit pas non plus qu’aucune écriture ne coïncidera avec une annulation ultérieure. Identifiez le point d’observation précis. L’habitude à retenir consiste à transmettre la durée de vie possédée et à conserver un cœur testable sans service démarré.

## Exemple détaillé

Source complète: [`cmd/l12/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l12/main.go).

```go
package main

import (
	"context"
	"encoding/json"
	"errors"
	"example.com/learn/go-for-csharp-java/internal/study"
	"example.com/learn/go-for-csharp-java/internal/webapi"
	"fmt"
	"net/http"
	"net/http/httptest"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	request := httptest.NewRequestWithContext(ctx, http.MethodGet, "/records", nil)
	response := httptest.NewRecorder()
	webapi.Handler().ServeHTTP(response, request)
	var records []study.Record
	if err := json.Unmarshal(response.Body.Bytes(), &records); err != nil {
		panic(err)
	}
	cancel()
	_, err := study.Count(ctx, records)
	fmt.Printf("status=%d records=%d cancelled=%t\n", response.Code, len(records), errors.Is(err, context.Canceled))
}
```

Depuis la racine du dépôt:

```sh
cd code/go-for-csharp-java
go run ./cmd/l12
```

**Sortie vérifiée — Go 1.27.1, Windows/amd64.**

```text
status=200 records=2 cancelled=true
```

## Lire, prévoir, puis vérifier

Avant l’exécution, suivez chaque valeur depuis sa déclaration jusqu’au résultat affiché. Notez quelle opération valide les données et laquelle transforme seulement des données déjà typées. Lancez ensuite la commande du dépôt et comparez toute sa sortie, y compris le saut de ligne final, avec examples.json. Un exemple conforme démontre ce jeu de données ; les tests écrits couvrent d’autres contrats. Modifiez une seule entrée à la fois, expliquez les conséquences et séparez votre essai des données publiées. Un résultat surprenant devient ainsi explicable sans changer silencieusement la promesse de la leçon.

## Exercices

1. Pourquoi aucun serveur public ni port ne sont-ils nécessaires ?

<details>
<summary>Solution 1</summary>

ServeHTTP est un appel d’interface ordinaire. httptest fournit une requête et un ResponseWriter qui conserve statut, en-têtes et corps en mémoire. Le programme exerce directement routage et encodage. Il démontre le contrat du gestionnaire, sans conclure sur sockets, TLS ou configuration de déploiement.

</details>

2. Pourquoi annuler avant l’appel de Count ?

<details>
<summary>Solution 2</summary>

Cela fixe l’ordre : Count reçoit un contexte déjà annulé et renvoie context.Canceled dès l’entrée, avant tout travail. Une pause ne prouverait pas cet ordre de façon fiable. Dans une vraie requête, l’annulation peut arriver en cours d’exécution ; les opérations doivent l’observer et documenter leur contrat d’achèvement.

</details>

## Sources officielles

- [http.Handler](https://pkg.go.dev/net/http#Handler)
- [http.ServeMux](https://pkg.go.dev/net/http#ServeMux)
- [httptest.ResponseRecorder](https://pkg.go.dev/net/http/httptest#ResponseRecorder)
- [context.WithCancel](https://pkg.go.dev/context#WithCancel)

[Leçon suivante](../13-testing/) · [Journal](../journal/)
