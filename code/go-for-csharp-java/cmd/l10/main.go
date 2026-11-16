package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	labels := study.Map(study.Fixture(), func(record study.Record) string { return record.Label() })
	fmt.Printf("labels=%v\n", labels)
}
