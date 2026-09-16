using System.Globalization;
using System.Text;
using System.Xml;
using System.Xml.Linq;

namespace PetriNets;

/// <summary>
/// Reads and writes the Petri Net Markup Language of ISO/IEC 15909-2, in its
/// P/T net type (http://www.pnml.org/version-2009/grammar/ptnet). Only the part every
/// tool agrees on is handled: places with an initial marking, transitions, arcs with an
/// inscription, and names. Graphics, tool-specific sections and pages beyond the first
/// are read and ignored, and not written back.
/// </summary>
public static class Pnml
{
    public const string PnmlNamespace = "http://www.pnml.org/version-2009/grammar/pnml";
    public const string PtNetType = "http://www.pnml.org/version-2009/grammar/ptnet";

    private static readonly XNamespace Ns = PnmlNamespace;

    public static PetriNet Load(string path) => Parse(File.ReadAllText(path));

    public static PetriNet Parse(string xml)
    {
        var document = XDocument.Parse(xml);
        var net = document.Descendants(Ns + "net").FirstOrDefault()
                  ?? document.Descendants("net").FirstOrDefault()
                  ?? throw new FormatException("No <net> element: this is not a PNML document.");
        var ns = net.Name.Namespace;

        var type = (string?)net.Attribute("type");
        if (type is not null && type != PtNetType)
            throw new NotSupportedException($"Net type {type} is not the P/T net type {PtNetType}.");

        var name = Text(net.Element(ns + "name")) ?? (string?)net.Attribute("id") ?? "net";

        var places = new List<Place>();
        var initial = new List<int>();
        foreach (var element in net.Descendants(ns + "place"))
        {
            var id = Id(element);
            places.Add(new Place(id, Text(element.Element(ns + "name")) ?? id));
            var marking = Text(element.Element(ns + "initialMarking"));
            initial.Add(marking is null ? 0 : int.Parse(marking.Trim(), CultureInfo.InvariantCulture));
        }

        var transitions = net.Descendants(ns + "transition")
            .Select(element => { var id = Id(element); return new Transition(id, Text(element.Element(ns + "name")) ?? id); })
            .ToList();

        var arcs = new List<Arc>();
        foreach (var element in net.Descendants(ns + "arc"))
        {
            var source = (string?)element.Attribute("source") ?? throw new FormatException("An <arc> has no source.");
            var target = (string?)element.Attribute("target") ?? throw new FormatException("An <arc> has no target.");
            var inscription = Text(element.Element(ns + "inscription"));
            arcs.Add(new Arc(source, target, inscription is null ? 1 : int.Parse(inscription.Trim(), CultureInfo.InvariantCulture)));
        }

        return new PetriNet(name, places, transitions, arcs, new Marking([.. initial]));
    }

    /// <summary>Writes the net as PNML, with two-space indentation and LF line endings, so the files compare cleanly.</summary>
    public static string Write(PetriNet net)
    {
        ArgumentNullException.ThrowIfNull(net);
        var page = new XElement(Ns + "page", new XAttribute("id", "page1"));

        for (var p = 0; p < net.Places.Count; p++)
        {
            var place = new XElement(Ns + "place",
                new XAttribute("id", net.Places[p].Id),
                Named(net.Places[p].Name));
            if (net.InitialMarking[p] != 0)
                place.Add(new XElement(Ns + "initialMarking", new XElement(Ns + "text", net.InitialMarking[p])));
            page.Add(place);
        }

        foreach (var transition in net.Transitions)
            page.Add(new XElement(Ns + "transition", new XAttribute("id", transition.Id), Named(transition.Name)));

        var index = 0;
        foreach (var arc in net.Arcs)
        {
            var element = new XElement(Ns + "arc",
                new XAttribute("id", $"a{++index}"),
                new XAttribute("source", arc.Source),
                new XAttribute("target", arc.Target));
            if (arc.Weight != 1)
                element.Add(new XElement(Ns + "inscription", new XElement(Ns + "text", arc.Weight)));
            page.Add(element);
        }

        var document = new XDocument(
            new XDeclaration("1.0", "UTF-8", null),
            new XElement(Ns + "pnml",
                new XElement(Ns + "net",
                    new XAttribute("id", "n1"),
                    new XAttribute("type", PtNetType),
                    Named(net.Name),
                    page)));

        // A StringWriter reports UTF-16, and XmlWriter copies that into the declaration: say UTF-8 instead,
        // since the file is written as UTF-8 and a reader that believes the declaration would be misled.
        using var text = new Utf8StringWriter();
        var settings = new XmlWriterSettings { Indent = true, IndentChars = "  ", Encoding = Encoding.UTF8, NewLineChars = "\n" };
        using (var writer = XmlWriter.Create(text, settings))
            document.Save(writer);
        return text.ToString().Replace("\r\n", "\n") + "\n";
    }

    public static void Save(PetriNet net, string path) => File.WriteAllText(path, Write(net));

    private sealed class Utf8StringWriter : StringWriter
    {
        public override Encoding Encoding => Encoding.UTF8;
    }

    private static XElement Named(string name) => new(Ns + "name", new XElement(Ns + "text", name));

    private static string Id(XElement element) =>
        (string?)element.Attribute("id") ?? throw new FormatException($"A <{element.Name.LocalName}> has no id.");

    private static string? Text(XElement? element)
    {
        if (element is null) return null;
        var text = element.Element(element.Name.Namespace + "text")?.Value ?? element.Value;
        return string.IsNullOrWhiteSpace(text) ? null : text.Trim();
    }
}
