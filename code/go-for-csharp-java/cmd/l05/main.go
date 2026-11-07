package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	totals := make(map[string]study.Minutes)
	for _, record := range study.Fixture() {
		totals[record.Name] += record.Minutes
	}
	minutes, present := totals["missing"]
	fmt.Printf("go=%d missing=%d present=%t\n", totals["go"], minutes, present)
}
