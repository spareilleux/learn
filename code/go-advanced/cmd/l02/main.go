package main

import (
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	source := []byte{1, 2}
	copy := domain.Clone(source)
	source[0] = 9
	fmt.Println(source, copy)
}
