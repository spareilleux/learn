package cli

import (
	"flag"
	"fmt"
	"io"
	"os"
	"strings"

	"example.com/learn/go-for-csharp-java/internal/study"
)

func Run(args []string, in io.Reader, out, errOut io.Writer) int {
	flags := flag.NewFlagSet("study-log", flag.ContinueOnError)
	flags.SetOutput(errOut)
	minimum := flags.Int("min", 0, "minimum minutes")
	filename := flags.String("file", "", "JSON file, or - for standard input; default uses sample")
	if err := flags.Parse(args); err != nil {
		if err == flag.ErrHelp {
			return 0
		}
		return 2
	}
	if *minimum < 0 || flags.NArg() != 0 {
		fmt.Fprintln(errOut, "invalid arguments")
		return 2
	}
	reader := io.Reader(strings.NewReader(study.Sample))
	if *filename == "-" {
		reader = in
	}
	if *filename != "" && *filename != "-" {
		file, err := os.Open(*filename)
		if err != nil {
			fmt.Fprintln(errOut, "input:", err)
			return 1
		}
		defer file.Close()
		reader = file
	}
	records, err := study.Load(reader)
	if err != nil {
		fmt.Fprintln(errOut, "input:", err)
		return 1
	}
	selected := study.Select(records, study.Minutes(*minimum))
	for _, record := range selected {
		if _, err := fmt.Fprintf(out, "%s: %d min\n", record.Name, record.Minutes); err != nil {
			fmt.Fprintln(errOut, "output:", err)
			return 1
		}
	}
	if _, err := fmt.Fprintf(out, "total: %d min\n", study.Total(selected)); err != nil {
		fmt.Fprintln(errOut, "output:", err)
		return 1
	}
	return 0
}
