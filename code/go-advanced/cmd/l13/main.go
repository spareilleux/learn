package main

import (
	"example.com/learn/go-advanced/provenance"
	"fmt"
)

func main() {
	path, ok := provenance.MainModule()
	if !ok {
		panic("build info unavailable")
	}
	fmt.Println(path)
}
