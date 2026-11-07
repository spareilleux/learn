package main

import (
	"bytes"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"io/fs"
	"testing/fstest"
	"unicode/utf8"
)

func main() {
	disk := fstest.MapFS{"records.json": {Data: []byte(study.Sample)}}
	data, err := fs.ReadFile(disk, "records.json")
	if err != nil {
		panic(err)
	}
	records, err := study.Load(bytes.NewReader(data))
	if err != nil {
		panic(err)
	}
	fmt.Printf("records=%d bytes=%d runes=%d\n", len(records), len("café"), utf8.RuneCountInString("café"))
}
