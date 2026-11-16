package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	records := study.Select(study.Fixture(), 20)
	fmt.Printf("selected=%d total=%d\n", len(records), study.Total(records))
}
