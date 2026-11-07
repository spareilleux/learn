package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"unicode/utf8"
)

func main() {
	name := "café"
	minutes := study.Minutes(20)
	fmt.Printf("bytes=%d runes=%d double=%d\n", len(name), utf8.RuneCountInString(name), minutes.Double())
}
