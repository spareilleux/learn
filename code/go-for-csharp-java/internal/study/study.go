package study

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"slices"
	"unicode/utf8"
)

const Course = "study-log"
const Sample = `[{"name":"types","minutes":15},{"name":"go","minutes":25}]`

var ErrInvalid = errors.New("invalid record")

type Minutes int

func (m Minutes) Double() Minutes { return m * 2 }

type Record struct {
	Name    string  `json:"name"`
	Minutes Minutes `json:"minutes"`
}

func (r Record) Label() string  { return r.Name }
func (r *Record) Add(n Minutes) { r.Minutes += n }

func Fixture() []Record {
	return []Record{{Name: "types", Minutes: 15}, {Name: "go", Minutes: 25}}
}

func Total(records []Record) Minutes {
	var total Minutes
	for _, record := range records {
		total += record.Minutes
	}
	return total
}

func Select(records []Record, minimum Minutes) []Record {
	selected := make([]Record, 0, len(records))
	for _, record := range records {
		if record.Minutes >= minimum {
			selected = append(selected, record)
		}
	}
	return selected
}

func Clone(records []Record) []Record { return slices.Clone(records) }

func Map[T, U any](values []T, convert func(T) U) []U {
	result := make([]U, len(values))
	for i, value := range values {
		result[i] = convert(value)
	}
	return result
}

func Load(reader io.Reader) ([]Record, error) {
	data, err := io.ReadAll(reader)
	if err != nil {
		return nil, fmt.Errorf("read records: %w", err)
	}
	if !utf8.Valid(data) {
		return nil, fmt.Errorf("UTF-8: %w", ErrInvalid)
	}
	var records []Record
	if err := json.Unmarshal(data, &records); err != nil {
		return nil, fmt.Errorf("decode records: %w", err)
	}
	if records == nil {
		return nil, fmt.Errorf("array required: %w", ErrInvalid)
	}
	for i, record := range records {
		if record.Name == "" || record.Minutes < 0 {
			return nil, fmt.Errorf("record %d: %w", i, ErrInvalid)
		}
	}
	return records, nil
}

func Stream(ctx context.Context, records []Record) <-chan Record {
	out := make(chan Record)
	go func() {
		defer close(out)
		for _, record := range records {
			select {
			case <-ctx.Done():
				return
			case out <- record:
			}
		}
	}()
	return out
}

func Count(ctx context.Context, records []Record) (int, error) {
	if err := ctx.Err(); err != nil {
		return 0, err
	}
	count := 0
	for range Stream(ctx, records) {
		count++
	}
	if err := ctx.Err(); err != nil {
		return 0, err
	}
	return count, nil
}
