package main

import (
	"errors"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"strings"
)

func main() {
	records, err := study.Load(strings.NewReader(study.Sample))
	if err != nil {
		panic(err)
	}
	_, invalid := study.Load(strings.NewReader(`[{"name":"","minutes":1}]`))
	fmt.Printf("total=%d invalid=%t\n", study.Total(records), errors.Is(invalid, study.ErrInvalid))
}
