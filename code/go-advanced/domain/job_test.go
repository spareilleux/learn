package domain

import (
	"errors"
	"testing"
)

func TestOwnership(t *testing.T) {
	input := []int{2, 3}
	job, err := NewJob("sum", input)
	if err != nil {
		t.Fatal(err)
	}
	input[0] = 99
	if job.Total() != 5 {
		t.Fatalf("caller mutation changed total: %d", job.Total())
	}
	source := []byte{1, 2}
	clone := Clone(source)
	source[0] = 9
	if clone[0] != 1 {
		t.Fatal("clone aliases input")
	}
}
func TestErrors(t *testing.T) {
	_, err := NewJob(" ", nil)
	if !errors.Is(err, ErrInvalid) {
		t.Fatal("missing invalid identity")
	}
	if Validate("ok") != nil {
		t.Fatal("success is not nil")
	}
	if TypedNil() == nil {
		t.Fatal("typed nil lost dynamic type")
	}
	var validation *ValidationError
	if !errors.As(Validate(""), &validation) || validation.Field != "name" {
		t.Fatal("typed error contract")
	}
}
