package main

import (
	"bytes"
	"example.com/learn/go-advanced/framing"
	"fmt"
)

func main() {
	var wire bytes.Buffer
	if err := framing.Write(&wire, []byte("Go")); err != nil {
		panic(err)
	}
	payload, err := framing.Read(&wire)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(payload))
}
