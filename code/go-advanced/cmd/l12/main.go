package main

import (
	"example.com/learn/go-advanced/encodingx"
	"fmt"
)

func main() {
	value := encodingx.Record{Name: "sum", Values: []int{2, 3}}
	data, err := encodingx.Encode(value)
	if err != nil {
		panic(err)
	}
	decoded, err := encodingx.Decode(data)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(data))
	fmt.Println(decoded.Name, encodingx.Fields(decoded))
}
