package main

import (
	"errors"
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	fmt.Println(domain.TypedNil() == nil, domain.Validate("ok") == nil)
	var detail *domain.ValidationError
	fmt.Println(errors.As(domain.Validate(""), &detail), detail.Field)
}
