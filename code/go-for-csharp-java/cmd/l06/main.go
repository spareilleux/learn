package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	record := study.Fixture()[0]
	copy := record
	copy.Add(5)
	record.Add(10)
	fmt.Printf("record=%d copy=%d\n", record.Minutes, copy.Minutes)
}
