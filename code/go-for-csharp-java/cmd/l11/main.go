package main

import (
	"context"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	var total study.Minutes
	for record := range study.Stream(ctx, study.Fixture()) {
		total += record.Minutes
	}
	fmt.Printf("stream-total=%d\n", total)
}
