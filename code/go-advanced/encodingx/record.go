package encodingx

import (
	"encoding/json/v2"
	"reflect"
)

type Record struct {
	Name   string `json:"name"`
	Values []int  `json:"values"`
}

func Encode(value Record) ([]byte, error) { return json.Marshal(value) }
func Decode(data []byte) (Record, error) {
	var value Record
	err := json.Unmarshal(data, &value, json.RejectUnknownMembers(true))
	return value, err
}
func Fields(value any) int {
	t := reflect.TypeOf(value)
	if t == nil || t.Kind() != reflect.Struct {
		return 0
	}
	return t.NumField()
}
