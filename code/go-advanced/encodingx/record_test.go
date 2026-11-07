package encodingx

import (
	"reflect"
	"testing"
)

func TestRecordRoundTrip(t *testing.T) {
	want := Record{Name: "sum", Values: []int{2, 3}}
	data, err := Encode(want)
	if err != nil {
		t.Fatal(err)
	}
	got, err := Decode(data)
	if err != nil || !reflect.DeepEqual(got, want) {
		t.Fatal(got, err)
	}
	if _, err := Decode([]byte(`{"name":"sum","surprise":1}`)); err == nil {
		t.Fatal("unknown field accepted")
	}
	if Fields(want) != 2 || Fields(nil) != 0 || Fields(3) != 0 {
		t.Fatal("reflection boundary")
	}
}
