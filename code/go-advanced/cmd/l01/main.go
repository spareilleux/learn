package main

import (
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	job, err := domain.NewJob("sum", []int{2, 3})
	if err != nil {
		panic(err)
	}
	fmt.Println(job.Name, job.Total())
}
