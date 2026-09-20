open System

type Parser<'value> =
    private
    | Parser of (string -> Result<'value * string, string>)

module Parser =
    let run (Parser parse) input = parse input

    let result value =
        Parser(fun input -> Ok(value, input))

    let bind next parser =
        Parser(fun input ->
            match run parser input with
            | Error error -> Error error
            | Ok(value, rest) -> run (next value) rest)

    let literal (expected: string) =
        Parser(fun input ->
            if input.StartsWith(expected, StringComparison.Ordinal) then
                Ok(expected, input[expected.Length..])
            else
                Error $"expected '{expected}'")

    let satisfy label predicate =
        Parser(fun input ->
            if String.IsNullOrEmpty input then
                Error $"expected {label}, got end of input"
            elif predicate input[0] then
                Ok(input[0], input[1..])
            else
                Error $"expected {label}, got '{input[0]}'")

    let optionalChar choices =
        Parser(fun input ->
            if not (String.IsNullOrEmpty input) && List.contains input[0] choices then
                Ok(Some input[0], input[1..])
            else
                Ok(None, input))

    let endOfInput =
        Parser(fun input ->
            if String.IsNullOrEmpty input then
                Ok((), input)
            else
                Error $"expected end of input, got \"{input}\"")

type ParserBuilder() =
    member _.Bind(parser, next) = Parser.bind next parser
    member _.Return(value) = Parser.result value
    member _.ReturnFrom(parser) = parser

let parser = ParserBuilder()

type Note =
    { Name: string
      Octave: int }

let noteParser =
    parser {
        let! _ = Parser.literal "note "
        let! letter = Parser.satisfy "note letter A-G" (fun value -> value >= 'A' && value <= 'G')
        let! accidental = Parser.optionalChar [ '#'; 'b' ]
        let! octave = Parser.satisfy "octave 0-9" Char.IsDigit
        do! Parser.endOfInput

        let name =
            match accidental with
            | Some symbol -> $"{letter}{symbol}"
            | None -> string letter

        return
            { Name = name
              Octave = int (string octave) }
    }

let show input =
    match Parser.run noteParser input with
    | Ok(note, _) -> printfn "OK %-13s -> %s%d" input note.Name note.Octave
    | Error error -> printfn "ERROR %-10s -> %s" input error

show "note C#4"
show "note Eb3"
show "note H2"
show "note C#4 tail"
