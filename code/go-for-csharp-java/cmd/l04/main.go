package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	original := study.Fixture()
	alias := original[:1]
	detached := study.Clone(alias)
	alias[0].Minutes = 30
	fmt.Printf("original=%d clone=%d\n", original[0].Minutes, detached[0].Minutes)
}
