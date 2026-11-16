package main

import (
	"context"
	"example.com/learn/go-advanced/pipeline"
	"fmt"
)

func main() {
	values, err := pipeline.Squares(context.Background(), []int{1, 2, 3}, 2)
	if err != nil {
		panic(err)
	}
	fmt.Println(values)
}
