package main

import (
	"example.com/learn/go-advanced/pipeline"
	"fmt"
	"sync"
)

func main() {
	var c pipeline.Counter
	var group sync.WaitGroup
	for range 4 {
		group.Go(func() {
			for range 25 {
				c.Add()
			}
		})
	}
	group.Wait()
	fmt.Println(c.Value())
}
