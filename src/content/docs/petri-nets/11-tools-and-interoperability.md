---
title: "11. Tools and interoperability"
description: PNML is the one thing every Petri net tool agrees on — what the analyser writes, what a round trip keeps and drops, what happened when it was handed sixteen files written by another tool, and the one defect that found, plus what TINA, LoLA, CPN Tools, GreatSPN, TAPAAL and ProM each do that this course does not.
sidebar:
  order: 11
---

Full code: [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). This lesson is printed by `dotnet run --project Examples -c Release -- l11`, compared with [`expected/l11.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l11.txt).

Ten lessons have been written against one analyser, which I wrote, on nets I also wrote. That is a closed loop, and a closed loop is how a course quietly teaches its own bugs.

The escape from it is [PNML](https://www.pnml.org/), the Petri Net Markup Language — an XML format standardised as [ISO/IEC 15909-2:2011](https://www.iso.org/standard/43538.html) and the one thing the tools in this field agree on. A net written here can be checked by a model checker written by someone else, and a net from a published benchmark can be run through the analyser of this course.

This lesson does both directions and reports what broke.

## What the writer emits

```
== What the writer emits ==
<?xml version="1.0" encoding="utf-8"?>
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="n1" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <name>
      <text>queue-2</text>
    </name>
    <page id="page1">
      <place id="room">
        <name>
          <text>room</text>
        </name>
        <initialMarking>
          <text>2</text>
        </initialMarking>
      </place>
      <place id="jobs">
        <name>
          <text>jobs</text>
        </name>
      </place>
      <transition id="arrive">
        <name>
          <text>arrive</text>
        </name>
      </transition>
      <transition id="serve">
        <name>
          <text>serve</text>
        </name>
      </transition>
      <arc id="a1" source="room" target="arrive" />
      <arc id="a2" source="arrive" target="jobs" />
      <arc id="a3" source="jobs" target="serve" />
      <arc id="a4" source="serve" target="room" />
    </page>
  </net>
</pnml>
```

Four things in that file are worth naming, because each is a place tools disagree.

- **the `type` attribute** is a URI, and it is the whole contract. `…/grammar/ptnet` means a place/transition net: tokens are indistinguishable, arcs carry integer weights. A different URI is a different language in the same syntax, and the reader must refuse it rather than guess.
- **`<page>`** exists because PNML models a *drawing*, and drawings have pages. The analyser has no use for pages and writes exactly one; a file that arrives with several is flattened.
- **every value is wrapped in `<text>`**, because the standard lets a value carry graphics, a font, a tool-specific annotation, and a label offset alongside its content. The number is never the element's own text.
- **absence means the default.** `jobs` has no `<initialMarking>` and holds zero; the arcs have no `<inscription>` and weigh one. Writing them would be legal and noisier.

## Reading back what we wrote

Interoperability starts at home. If the reader and the writer disagree, no other tool matters:

```
== Every net of the course, written and read back ==
24 nets written, parsed and written again
identical text and identical reachability graph: all of them
```

Twenty-four nets, each written to PNML, parsed back, and written again. The two texts are byte-identical and the reachability graph has the same number of states. `check.sh` runs that on every commit, which makes the PNML files in [`nets/`](https://github.com/spareilleux/learn/tree/main/code/petri-nets/nets) the same objects as the C# definitions rather than a copy that drifts.

A round trip is not lossless, and being explicit about that is the point:

```
== What a round trip drops ==
kept:    place and transition ids and names, arc weights, the initial marking
dropped: <graphics> positions and offsets, <toolspecific> blocks, page structure
refused: any <net type> that is not the P/T net type
```

Everything dropped is about *drawing* the net, not about what it does. Read a file from a graphical editor, analyse it, write it back, and the layout is gone: the net is the same net and the picture has to be laid out again. That is the honest cost of a tool that models the mathematics and not the diagram.

## Reading a file written by someone else

The real test. [ePNK](http://www2.imm.dtu.dk/~eki/projects/ePNK/) is an Eclipse-based PNML tool by Ekkart Kindler, one of the authors of the standard; its examples bundle ships the P/T net sample from ISO/IEC 15909-2 itself, plus fifteen high-level nets. Sixteen files, none of them mine:

```
== Reading another tool ==
ConsensusInNetworks.pnml              refused: Net type highlevelnet is not the P/T net type ptnet.
Echo.pnml                             refused: Net type highlevelnet is not the P/T net type ptnet.
MinDistance.pnml                      refused: Net type highlevelnet is not the P/T net type ptnet.
SimpleTransmissionProtocol.pnml       refused: Net type highlevelnet is not the P/T net type ptnet.
TransmissionProtocolLossyChannel.pnml refused: Net type highlevelnet is not the P/T net type ptnet.
factorize.pnml                        refused: Net type highlevelnet is not the P/T net type ptnet.
factorize2.pnml                       refused: Net type highlevelnet is not the P/T net type ptnet.
lists.pnml                            refused: Net type highlevelnet is not the P/T net type ptnet.
prime-factors.pnml                    refused: Net type highlevelnet is not the P/T net type ptnet.
runtimeValueEval.pnml                 refused: Net type highlevelnet is not the P/T net type ptnet.
samplePTnet.pnml                      read: 1 places, 1 transitions, "An example P/T-net"
samplePTnetAdjustedPositions.pnml     read: 1 places, 1 transitions, "An example P/T-net"
sampleSNPrio.pnml                     refused: Net type symmetricnet is not the P/T net type ptnet.
sampleSNPrioDeclarationsOnPage.pnml   refused: Net type symmetricnet is not the P/T net type ptnet.
sampleSNPrioFixedNames.pnml           refused: Net type symmetricnet is not the P/T net type ptnet.
simple-dot-net.pnml                   refused: Net type pt-hlpng is not the P/T net type ptnet.
```

:::note[This block is not produced by `check.sh`]
The ePNK examples are [EPL-1.0](https://www.eclipse.org/legal/epl-v10.html) and are not vendored into this repository, so `check.sh` runs `l11` without them and the section prints a pointer instead. To reproduce: download [`ePNK-1.0.0-examples.zip`](http://www2.imm.dtu.dk/~eki/projects/ePNK/downloads/ePNK-1.0.0-examples.zip), unzip the `.pnml` files into one directory, and run `dotnet run --project Examples -c Release -- l11 <that directory>`. The listing above is from that run on 2026-09-22.
:::

Two accepted, fourteen refused, and both halves are the result.

**The refusals are correct, and the last one is the interesting one.** `simple-dot-net.pnml` is a *P/T net* — one token type, no data — written in the high-level grammar with the colour set `dot`, which has exactly one value. It behaves like every net in this course and it is not readable by a reader that checks the type URI. Three of the refusals are symmetric nets, which are the restricted coloured nets [lesson 8](../08-coloured-nets/) named. The moral is that "PNML" is not one format: it is a syntax plus a type URI, and a tool speaks some of the types.

**The acceptances found a defect.** The ISO sample file, as ePNK writes it, is built to be awkward on purpose:

```xml
<net type="http://www.pnml.org/version-2009/grammar/ptnet" id="n1">
  <page id="top-level">
    <name><text>An example P/T-net</text></name>
    <place id="p1">
      <name><graphics><offset y="-10.0"/></graphics><text>ready</text></name>
      <initialMarking>
        <toolspecific tool="org.pnml.tool" version="1.0">…</toolspecific>
        <text>3</text>
      </initialMarking>
    </place>
    <transition id="t1"><graphics><position x="60.0" y="20.0"/></graphics></transition>
    <arc id="a1" source="p1" target="t1">
      <inscription><graphics><offset y="5.0"/></graphics><text>2</text></inscription>
    </arc>
  </page>
</net>
```

Four traps, and the reader survived three of them. The marking is 3 although a `<toolspecific>` block comes first; the arc weight is 2 although a `<graphics>` comes first; the transition has no `<name>` at all and falls back to its id.

The fourth it failed. **The name is on the `<page>`, not on the `<net>`**, and the reader only looked at the net — so the file came back called `n1`, its id. The standard allows a name on either, tools differ, and the analyser had silently picked one. Three lines fixed it, a unit test now carries the whole awkward shape, and the listing above is from after the fix.

That is the one defect this lesson found, and it was found by the only method that finds this class of defect: reading a file nobody in this repository wrote.

## What the other tools are for

The analyser of this course is a teaching instrument. It builds a reachability graph in memory with a hard limit, enumerates siphons by brute force over subsets of places, and solves a Markov chain by dense Gaussian elimination. Every one of those is the wrong algorithm at scale, on purpose, because each is short enough to read.

These are the tools that do it properly. None is required by this course; all of them speak PNML, most of them also speak their own native format.

| Tool | What it is for | Native format |
|---|---|---|
| [TINA](https://projects.laas.fr/tina/) | time Petri nets in the sense of Merlin, state classes, LTL/CTL model checking | `.net`, `.ndr`, reads PNML |
| [LoLA](https://theo.informatik.uni-rostock.de/theo-forschung/tools/lola/) | very fast reachability and CTL\* on huge P/T nets, with stubborn sets and symmetry | own format, reads PNML |
| [CPN Tools](https://cpntools.org/) | coloured nets with CPN ML inscriptions, simulation, state space with symmetry | `.cpn`, exports PNML |
| [GreatSPN](https://www.di.unito.it/~greatspn/index.html) | GSPN and stochastic analysis, the models of [lesson 9](../09-time-and-probability/) at scale | own format, reads PNML |
| [TAPAAL](https://www.tapaal.net/) | timed-arc Petri nets, verification by translation to timed automata | `.tapn`, reads PNML |
| [Snoopy](https://www-dssz.informatik.tu-cottbus.de/DSSZ/Software/Snoopy) | drawing and simulating several net classes, strong in systems biology | own, exports PNML |
| [PIPE](https://github.com/sarahtattersall/PIPE) | a Java editor and analyser, the easiest one to read the source of | PNML natively |
| [ePNK](http://www2.imm.dtu.dk/~eki/projects/ePNK/) | the reference implementation of the standard's metamodel | PNML natively |
| [ProM](https://promtools.org/) | process mining, the other direction of [lesson 10](../10-workflows/) | XES logs, PNML nets |

The place to see them against each other is the [Model Checking Contest](https://mcc.lip6.fr/), which runs them every year on a public collection of nets, in PNML, with published results. That collection is also the honest answer to "is my analyser fast?" — it is not, and the contest says by how much. *To verify: I have not submitted anything to it, nor run its benchmark set.*

## Where this stops

- **A shared syntax is not a shared semantics.** Every file above parsed as XML. Fourteen of them were still unreadable, because the type URI names a different language. PNML makes exchange *possible* between tools that implement the same type; it does not make every net portable.
- **The standard has three parts and the useful one costs money.** [Part 1](https://www.iso.org/standard/67235.html) is the concepts, [part 2](https://www.iso.org/standard/43538.html) the transfer format, [part 3](https://www.iso.org/standard/81504.html) the extensions. The grammars are free at [pnml.org](https://www.pnml.org/) — but only the core model and the type-independent ones; the P/T grammar is not among the published `.rng` files, so the analyser's output has never been validated against a schema. *To verify.*
- **Nobody agrees where the layout lives.** Positions are in `<graphics>` and are optional, so a net exchanged between two editors usually arrives in a heap. Every tool has its own `<toolspecific>` block, which by design nobody else reads.
- **Reading is easier than being read.** Writing PNML another tool accepts is the easy half, because the syntax is small. Reading what other tools write is where the work is: names in unexpected places, several pages, arcs between arcs in extensions, and inscriptions that are expressions rather than numbers.

## Key takeaways

- **PNML is a syntax plus a type URI.** The URI is the contract; a reader that ignores it will happily misread a coloured net as a P/T net.
- The analyser **round-trips all 24 course nets** byte-identically, and `check.sh` checks it on every commit, so the `.pnml` files and the C# definitions cannot drift.
- A round trip **keeps the net and loses the picture**. That is a design choice, and it means a graphical editor and an analyser are not interchangeable.
- **Read a file nobody on your side wrote.** Sixteen files from another tool found one real defect in three minutes; ten lessons of self-consistent output had found none.
- The defect was a **name on the `<page>` instead of the `<net>`** — the kind of thing a standard permits, tools disagree about, and only a foreign file reveals.
- A P/T net can be written in the **high-level grammar** with a one-value colour set, and is then unreadable to a P/T reader. Same net, different language.
- The real tools are **TINA, LoLA, CPN Tools, GreatSPN, TAPAAL, Snoopy, PIPE, ePNK and ProM**. This course's analyser is not one of them and does not try to be.

## Exercises

1. Take `nets/queue-5.pnml`, change the `type` URI to the symmetric net one, and predict what the reader does before running it.
2. The round trip drops `<graphics>`. Say what would have to change in `PetriNet` to keep it, and whether you would.
3. Write by hand the smallest PNML file the reader accepts, and say which elements you left out and why that is legal.
4. The analyser flattens several `<page>` elements into one. Name a net for which that loses information that matters, and one for which it does not.

<details>
<summary>Solutions</summary>

**1.** It throws `NotSupportedException` with the message `Net type symmetricnet is not the P/T net type ptnet.` — and that is exactly the behaviour a unit test in `PnmlTests` pins, by doing that substitution on the handshake net. The file is still valid PNML and still parses as XML; only the reader refuses it. Note what would happen without the check: a symmetric net's places carry a colour-set declaration and its arcs carry expressions rather than integers, so the parse would fail later, in `int.Parse`, with a message about a string that is not a number — a worse error about a real problem.

**2.** `Place` and `Transition` would need a position, `Arc` a list of intermediate points, and every name an offset; the writer would emit them and the reader would keep them. That is perhaps forty lines.

I would not. The analyser never draws anything — [lesson 1](../01-why-petri-nets/) hands the drawing to Mermaid, which lays out the graph itself — so the coordinates would be carried through the whole program without ever being read. The right place for that data is a tool whose job is the picture, and the right thing for this one to do is to say plainly that it drops it.

**3.** A net with one place, one transition and one arc, no names, no marking, no inscription:

```xml
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="n" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <page id="p">
      <place id="p1"/>
      <transition id="t1"/>
      <arc id="a1" source="p1" target="t1"/>
    </page>
  </net>
</pnml>
```

The names are left out because an id is required and a name is not, so the reader falls back to the id — which is what happened to `t1` in the ISO sample. The marking is left out because absent means zero, and the inscription because absent means one. What cannot be left out is the `type` attribute, the ids, and the `source` and `target` of the arc: those are the net.

**4.** It matters for a net whose pages are a *decomposition* — one page per subsystem, joined by reference nodes, which is how a large industrial model stays readable. Flattening it keeps the mathematics and destroys the only structure a human had to navigate it by. It does not matter for a net whose pages are pagination: the same flat net split over two sheets so it prints. The analyser cannot tell those apart, which is the argument for saying that it flattens rather than pretending it preserves.

</details>

## Sources

- [PNML](https://www.pnml.org/), the format's home, with the free [RELAX NG grammars](http://www.pnml.org/version-2009/grammar/pnmlcoremodel.rng) for the core model.
- [ISO/IEC 15909-2:2011](https://www.iso.org/standard/43538.html), *Systems and software engineering — High-level Petri nets — Part 2: Transfer format*, with [part 1](https://www.iso.org/standard/67235.html) for the concepts and [part 3](https://www.iso.org/standard/81504.html) for the extensions. The records were checked on iso.org; the standards cost money and I have not read them. *To verify.*
- Hillah, Kordon, Petrucci and Trèves, "PNML Framework: An Extendable Reference Implementation of the Petri Net Markup Language", in *Applications and Theory of Petri Nets 2010*, Springer LNCS 6128, [doi:10.1007/978-3-642-13675-7_20](https://doi.org/10.1007/978-3-642-13675-7_20). Record confirmed through Crossref; not read. *To verify.*
- [ePNK](http://www2.imm.dtu.dk/~eki/projects/ePNK/), whose [examples bundle](http://www2.imm.dtu.dk/~eki/projects/ePNK/downloads/ePNK-1.0.0-examples.zip) provided the sixteen foreign files, under [EPL-1.0](https://www.eclipse.org/legal/epl-v10.html).
- [The Model Checking Contest](https://mcc.lip6.fr/), which runs these tools against each other on a public PNML collection every year.
- The implementation this lesson prints: [`Pnml.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Pnml.cs), with the reader, the writer and the tests, including the one that carries the ISO sample's awkward shape.
