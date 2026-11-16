package metrics

import "testing"

var sink int

func TestSum(t *testing.T) {
	if Sum([]int{2, 3, 4}) != 9 {
		t.Fatal("sum")
	}
}
func BenchmarkSum(b *testing.B) {
	values := make([]int, 1024)
	for i := range values {
		values[i] = i
	}
	b.ReportAllocs()
	for b.Loop() {
		sink = Sum(values)
	}
}
