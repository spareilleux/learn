package main

import (
	"example.com/learn/go-advanced/metrics"
	"fmt"
)

func main() { fmt.Println(metrics.Sum([]int{1, 2, 3})) }
