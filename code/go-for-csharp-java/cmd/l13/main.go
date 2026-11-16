package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	records := study.Fixture()
	fmt.Printf("fixture-total=%d empty-total=%d\n", study.Total(records), study.Total(nil))
}
