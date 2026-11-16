package main

import (
	"example.com/learn/go-advanced/collection"
	"fmt"
	"slices"
)

func main() {
	values := collection.Map(slices.Values([]int{1, 2, 3}), func(v int) int { return v * 2 })
	fmt.Println(slices.Collect(values))
}
