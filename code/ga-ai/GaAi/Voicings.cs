namespace GaAi;

using GA.Business.Core.Analysis.Voicings;
using GA.Business.ML.Embeddings;
using GA.Business.ML.Embeddings.Services;
using GA.Business.ML.Rag;
using GA.Business.ML.Rag.Models;
using GA.Domain.Core.Instruments.Fretboard.Voicings.Core;
using GA.Domain.Core.Instruments.Positions;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Core.Primitives.Notes;
using GA.Domain.Services.Fretboard.Voicings.Analysis;

// A voicing after GA's pipeline: analysis, RAG document, raw 240-dim OPTIC-K vector
public sealed record Embedded(
    string Shape,
    Voicing Voicing,
    MusicalVoicingAnalysis Analysis,
    ChordVoicingRagDocument Doc,
    float[] Raw)
{
    public double[] RawDouble => Array.ConvertAll(Raw, v => (double)v);

    public float[] Slice(string partition)
    {
        var p = EmbeddingSchema.GetPartition(partition);
        return Raw[p.Start..(p.End + 1)];
    }
}

public static class Voicings
{
    // Standard tuning, low E to high E
    static readonly int[] OpenLowToHigh = [40, 45, 50, 55, 59, 64];

    static readonly MusicalEmbeddingGenerator Generator =
        new(new ModalVectorService(), new PhaseSphereService());

    // A chord chart shape, written low E to high E as guitarists do ("x32010" is open C).
    // GA numbers strings from the high E (string 1), so the positions are built high E first,
    // the order GA's own voicing generator uses.
    public static Voicing FromShape(string shape)
    {
        if (shape.Length != 6) throw new ArgumentException($"six strings expected: {shape}");
        var positions = new List<Position>();
        var notes = new List<MidiNote>();
        for (var str = 1; str <= 6; str++)
        {
            var c = shape[6 - str];
            var s = new Str(str);
            if (c is 'x' or 'X')
            {
                positions.Add(new Position.Muted(s));
                continue;
            }

            var fret = c - '0';
            var midi = new MidiNote(OpenLowToHigh[6 - str] + fret);
            positions.Add(new Position.Played(new PositionLocation(s, new Fret(fret)), midi));
            notes.Add(midi);
        }

        return new Voicing([.. positions], [.. notes]);
    }

    // The parser of GaMcpServer's ga_generate_voicing_embedding tool, copied from
    // GaMcpServer/Tools/VoicingEmbeddingTool.cs#L134-L173 (guitar only): it reads the
    // diagram's first element as string 1, the high E.
    public static Voicing FromMcpDiagram(string diagram)
    {
        int[] openMidi = [64, 59, 55, 50, 45, 40];
        var parts = diagram.Split('-');
        var positions = new List<Position>();
        var notes = new List<MidiNote>();
        for (var i = 0; i < parts.Length; i++)
        {
            var part = parts[i].Trim();
            var str = new Str(i + 1);
            if (part is "x" or "X")
            {
                positions.Add(new Position.Muted(str));
            }
            else
            {
                var fretValue = int.Parse(part);
                var midiNote = new MidiNote(openMidi[i] + fretValue);
                positions.Add(new Position.Played(new PositionLocation(str, new Fret(fretValue)), midiNote));
                notes.Add(midiNote);
            }
        }

        return new Voicing([.. positions], [.. notes]);
    }

    public static Embedded Embed(string shape) => Embed(shape, FromShape(shape));

    public static Embedded Embed(string label, Voicing voicing)
    {
        var analysis = VoicingAnalyzer.Analyze(voicing);
        var doc = VoicingDocumentFactory.FromAnalysis(voicing, analysis, tuningId: "guitar");
        var raw = Generator.GenerateEmbeddingAsync(doc).GetAwaiter().GetResult();
        return new Embedded(label, voicing, analysis, doc, raw);
    }

    public static string NoteName(int pitchClass) =>
        new[] { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }[((pitchClass % 12) + 12) % 12];
}
