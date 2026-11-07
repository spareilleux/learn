package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	fmt.Printf("module=%s records=%d\n", study.Course, len(study.Fixture()))
}
