package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

type Named interface{ Label() string }

func main() {
	var pointer *study.Record
	var named Named = pointer
	value := study.Fixture()[0]
	fmt.Printf("pointer-nil=%t interface-nil=%t label=%s\n", pointer == nil, named == nil, value.Label())
}
