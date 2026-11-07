package collection

import "iter"

func Map[A, B any](input iter.Seq[A], f func(A) B) iter.Seq[B] {
	return func(yield func(B) bool) {
		for value := range input {
			if !yield(f(value)) {
				return
			}
		}
	}
}

func Reverse(s string) string {
	r := []rune(s)
	for i, j := 0, len(r)-1; i < j; i, j = i+1, j-1 {
		r[i], r[j] = r[j], r[i]
	}
	return string(r)
}
