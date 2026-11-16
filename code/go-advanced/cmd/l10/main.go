package main

import (
	"example.com/learn/go-advanced/collection"
	"fmt"
)

func main() {
	text := "été Go"
	fmt.Println(collection.Reverse(text))
	fmt.Println(collection.Reverse(collection.Reverse(text)) == text)
}
