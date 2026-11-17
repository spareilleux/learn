---
title: "11. Counting without counting: Bloom filters, HyperLogLog, count-min, cuckoo"
description: "Four structures that answer membership, cardinality and frequency questions in a fixed amount of memory, measured in IX's ix-probabilistic against seven predictions written before the first run: all seven held, and two of them expose a documented bound that is wrong and a cuckoo filter that loses an item."
sidebar:
  order: 11
---

A hash set answers "have I seen this?" exactly, and it grows with every item. The four structures of IX's pinned [`ix-probabilistic`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic) crate answer that question and two others in memory fixed in advance. The price is a known, bounded error. This lesson measures that error against the formulas that promise it.

The seven predictions this lesson tests were [written in the journal](../journal/#2026-09-29--lesson-11-predicted-before-measuring) and committed before any of its code existed. [The results](../journal/#2026-09-29--lesson-11-measured) follow them. The experiments are in [`sketch.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/sketch.rs), one test per prediction. [`l11_sketches.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l11_sketches.rs) prints what they measure. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recomputes the formulas with Python and replays the hand-written HyperLogLog with numpy.

| Question | Structure | IX type | Error it allows |
|---|---|---|---|
| Is this item in the set? | Bloom filter | `bloom::BloomFilter` | False positives, never false negatives |
| How many distinct items? | HyperLogLog | `hyperloglog::HyperLogLog` | A relative error of about 1.04/√m |
| How often did this item occur? | Count-min sketch | `count_min::CountMinSketch` | Overcounts only, bounded with a stated probability |
| Is this item in the set, with deletions? | Cuckoo filter | `cuckoo::CuckooFilter` | False positives, and insertions that can fail |

All four hash with Rust's [`DefaultHasher`](https://doc.rust-lang.org/std/collections/hash_map/struct.DefaultHasher.html), which is deterministic for a given Rust version but, as its documentation says, not stable across releases. The items are the integers 0, 1, 2, …, so each experiment reads the same on every run.

## 1. A Bloom filter and its false positives

A [Bloom filter](https://doi.org/10.1145/362686.362692) is an array of m bits and k hash functions. Inserting an item sets the k bits its hashes point to. A query answers "maybe" when all k bits are set, and "no" as soon as one is not. An item that was inserted always finds its bits set, so there are no false negatives. An item that was not inserted can find its k bits set by others, which is a false positive.

For n items and a target rate p, the bits and hashes that minimise the rate are m = −n ln p / (ln 2)² and k = (m/n) ln 2. With random hashes, the rate after n insertions is then (1 − e^(−kn/m))^k. [`BloomFilter::new`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs#L31) uses the first two formulas, rounding both up. The hand sizing in `sketch.rs` finds the same m, and IX's hash count is read from the filter's serde form, since the field is private:

```text
== Bloom filter: new(10000, 0.01)
  hand sizing: m = 95851 bits, k = 7 hashes
  10000 inserted, IX m = 95851, k = 7: 0 false negatives, 1041 false positives in 100000 queries, rate 0.01041; theory 0.01004; estimated_fp_rate 0.01001
  20000 inserted, IX m = 95851, k = 7: 0 false negatives, 15616 false positives in 100000 queries, rate 0.15616; theory 0.15745; estimated_fp_rate 0.15898
```

At capacity, 1,041 of the 100,000 integers that were never inserted pass. The predicted interval, three standard deviations around 0.01004, was [0.00909, 0.01098]. At twice the capacity the rate is 15.6%, again inside its predicted interval. Nothing warns that the filter is past its capacity: `insert` returns nothing, and `len()` counts insertions without comparing them with anything.

[`estimated_fp_rate`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs#L82-L87) raises the share of set bits to the power k. It tracks the measured rate without knowing how many items went in, which makes it the check to run on a filter someone else filled. The bits are stored as a `Vec<bool>` ([`bloom.rs` 22](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs#L22)), one byte per bit. This filter therefore takes 95,851 bytes where a packed array would take 11,982, as the crate's `CONTRACTS.md` acknowledges.

## 2. HyperLogLog: how many distinct items

[HyperLogLog](https://dmtcs.episciences.org/3545) keeps m = 2^p small registers. Each item's hash picks a register with its low p bits. In the remaining bits, the position of the first 1 is its **rank**: rank r turns up once in about 2^r distinct hashes. Each register keeps the largest rank it has seen, and the estimate is a bias-corrected harmonic mean, α m² / Σ 2^(−register). Duplicates change nothing, because the same item always lands on the same register with the same rank. Below 2.5 m, where many registers are still zero, the estimator switches to linear counting, m ln(m / zeros).

Flajolet, Fusy, Gandouet and Meunier give the standard error as 1.04/√m. The hand version in `sketch.rs` implements the same estimator but hashes with splitmix64, so it shares nothing with IX's hashing. Over 100 disjoint sets of 100,000 integers with p = 10:

```text
== HyperLogLog, p = 10 (1024 registers): 100 disjoint sets of 100000 integers
  predicted standard error 1.04 / sqrt(1024) = 0.0325
  IX, DefaultHasher: RMS relative error 0.0354, mean 0.0028, worst 0.1038
  hand, splitmix64 : RMS relative error 0.0340, mean 0.0076, worst 0.1016
```

Both errors lie in the predicted interval, [0.0256, 0.0394]. A thousand bytes estimate 100,000 distinct items to within about 3.5% most of the time, and one set in 100 is off by 10%. numpy replays the hand version and prints the same three numbers.

The standard error is an asymptotic figure. The next table was not predicted: the same comparison at other cardinalities, 100 sets each.

```text
== HyperLogLog across cardinalities, p = 10, 100 sets each (not preregistered)
  n =    500: IX mean  0.0001, RMS 0.0225; hand mean -0.0011, RMS 0.0235
  n =   2000: IX mean  0.0020, RMS 0.0304; hand mean  0.0034, RMS 0.0289
  n =   2560: IX mean  0.0244, RMS 0.0402; hand mean  0.0234, RMS 0.0421
  n =   3000: IX mean  0.0118, RMS 0.0280; hand mean  0.0148, RMS 0.0289
  n =   4000: IX mean  0.0055, RMS 0.0257; hand mean  0.0052, RMS 0.0334
  n =   6000: IX mean  0.0031, RMS 0.0271; hand mean  0.0010, RMS 0.0321
  n =  10000: IX mean  0.0050, RMS 0.0296; hand mean  0.0026, RMS 0.0341
  n = 100000: IX mean  0.0028, RMS 0.0354; hand mean  0.0076, RMS 0.0340
  HyperLogLog::standard(): memory_bytes 16384, error_rate 0.0081
```

At n = 2,560 = 2.5 m, both implementations overestimate by 2.3 to 2.4% on average. With 100 sets, the standard error of a mean is about 0.0033, so this is roughly seven standard errors: a bias, not noise. This is exactly where [`count`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/hyperloglog.rs#L83-L89) leaves linear counting for the raw estimator, which is biased upwards at that size. [HyperLogLog++](https://research.google/pubs/hyperloglog-in-practice-algorithmic-engineering-of-a-state-of-the-art-cardinality-estimation-algorithm/) corrects the raw estimate with measured biases for that reason. Below the switch, linear counting is more accurate than 1.04/√m.

The last line shows the default: `standard()` uses p = 14 and 16,384 bytes. The module's first line promises "~1.6KB memory", which no precision gives.

## 3. Count-min: how often

A [count-min sketch](https://doi.org/10.1016/j.jalgor.2003.12.001) is a table of d rows of w counters. Adding an item increments one counter per row, chosen by that row's hash. Its estimate is the smallest of its d counters. Every counter an item touches holds its own count plus the counts of the items that share it, so the estimate never undercounts. Cormode and Muthukrishnan's bound is the reason the minimum works. With w = ⌈e/ε⌉ and d = ⌈ln(1/δ)⌉, the overcount exceeds εN with probability at most δ, where N is the total count. In terms of the width, that is e·N/w with probability 1 − e^(−d). One row exceeds e times its expected overcount with probability at most 1/e, by Markov's inequality, and d independent rows all do so with probability e^(−d).

The doc comment of [`CountMinSketch::new`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/count_min.rs#L22-L23) drops the e: "Error <= total_count / width with probability >= 1 - (1/e)^depth". N/w is the *expected* overcount of a row, and a row exceeds its expectation about half the time. The prediction was that more than e^(−3) of the items would break the documented bound, and fewer than e^(−3) would break the real one:

```text
== count-min sketch: new(100, 3), 10000 integers added 10 times each
  N = 100000; underestimates 0; mean overcount 911.3; max overcount 1180
  share above N/width = 1000: 0.0992 (binomial model 0.1058; the doc allows 0.0498)
  share above e N/width = 2718: 0.0000
  with_error(0.01, 0.05): width 272, depth 3
```

One item in ten overshoots by more than 1,000, twice what the doc comment allows. The binomial model behind the prediction treats each row's load as Binomial(9,999, 1/100) and gives 0.1058. No item comes near 2,718. [`with_error`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/count_min.rs#L35-L39) sizes the table correctly, with width ⌈e/0.01⌉ = 272 and depth ⌈ln 20⌉ = 3. Only the comment on `new` states the wrong bound.

## 4. Cuckoo filters: membership with deletion

A Bloom filter cannot forget an item, because its bits are shared. A [cuckoo filter](https://doi.org/10.1145/2674005.2674994) stores a short **fingerprint** of each item (16 bits in IX) in one of two buckets of 4 slots. The first bucket comes from the item's hash. The second is the first XOR a hash of the fingerprint, so either bucket can be computed from the other and the fingerprint alone ([`alt_index`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs#L147-L151)). When both buckets are full, the insertion evicts a fingerprint to its other bucket, which may evict another, up to 500 times. Deleting removes one copy of the fingerprint.

```text
== cuckoo filter: new(4096), integers 0, 1, 2, ... until an insert fails
  4096 slots; first failure inserting 3730, load factor 0.9106
  earlier integers no longer found: 1 [2498]; the failed integer found: true
  false positives on 100000 integers never inserted: 14, rate 0.00014
  a second filter on the same sequence: same failure true, contains disagreements 0
```

- **Load factor:** the first failure comes at 91% of the slots, above the predicted 0.90 but below the 95% that Fan, Andersen, Kaminsky and Mitzenmacher report for buckets of 4.
- **False positives:** 14 in 100,000. A query compares its fingerprint with the 8 slots of two buckets, 91% full, which gives about 8 × 0.91 / 65,536 ≈ 1.1 in 10,000.
- **The failed insertion:** [`insert`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs#L54-L75) put the new fingerprint in at the first kick and carried another one from bucket to bucket for 500 kicks. When it gives up, it returns false and drops the fingerprint it is still carrying.
  - **The result:** 3,730, the integer "not inserted", is found. 2,498, which was inserted successfully, is no longer found. That is a **false negative**, the one error a membership filter is expected not to make.
  - **Compared with the paper:** Algorithm 1 of Fan et al. does the same on failure, and the paper promises no false negatives only "as long as bucket overflow never occurs". The authors' reference implementation keeps the carried fingerprint in a one-entry victim cache instead ([`cuckoofilter.h`](https://github.com/efficient/cuckoofilter/blob/917583d6abef692dfa8e14453bd77d6e0b61eef3/src/cuckoofilter.h#L42-L48)).
  - **Compared with IX's documentation:** the doc comment of `insert` says only "Returns false if the filter is full", and neither it nor `CONTRACTS.md` mentions the loss.
- **Determinism:** the crate's `CONTRACTS.md` says victims are picked with `rand::random()` and that runs are not deterministic. Fan et al. do pick a random bucket and a random entry. IX always starts from the first bucket and picks the slot `fingerprint % len` ([`cuckoo.rs` 60](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs#L60)), and the crate does not depend on `rand`. Two filters fed the same integers fail at the same one and agree on all 100,000 probes.

```text
== cuckoo filter: the same integer inserted again and again
  insert(42) ten times: [true, true, true, true, true, true, true, true, false, false]; len 8
```

A cuckoo filter has no idea whether an item is already present. Each insertion stores another copy of the same fingerprint, and after 8 copies, the capacity of its two buckets, the next insertion fails. Fan et al. say so: cuckoo filters "are not suitable for applications that insert the same item more than 2b times". Check `contains` before inserting when the input can repeat, and never delete an item that was not inserted: another item with the same fingerprint in the same bucket would lose its copy.

## 5. The predictions, scored

| | Prediction, written before the first run | Measured | Verdict |
|---|---|---|---|
| P1 | Bloom at capacity: rate in [0.00909, 0.01098] | 0.01041 | Confirmed |
| P2 | Bloom at twice capacity: rate in [0.1540, 0.1609] | 0.15616 | Confirmed |
| P3 | HyperLogLog, p = 10: RMS error in [0.0256, 0.0394], mean within ±0.00975, for IX and by hand | 0.0354 and 0.0028; 0.0340 and 0.0076 | Confirmed |
| P4 | Count-min: more than 0.0498 of the items above N/w, in [0.07, 0.20]; fewer than 0.0498 above e·N/w | 0.0992; 0.0000 | Confirmed |
| P5 | Cuckoo: first failure at a load factor of at least 0.90 | 0.9106 | Confirmed |
| P6 | Cuckoo: after the first failure, an item inserted earlier is not found | 2,498 | Confirmed |
| P7 | Cuckoo: two filters fed the same sequence behave identically | Same failure, 0 disagreements | Confirmed |

The seven predictions held on the first run. P1 to P3 check that the structures meet their theory. P4, P6 and P7 were written to catch a discrepancy between IX's documentation and its code, found by reading it first: all three found one. None of the seven was adjusted after the run. The only change made afterwards is the number of sets in the table of section 2, which was not a prediction, and the journal says so.

## What to use for our repositories

- **Bloom filter:** size it for the largest set it will hold, since nothing warns once it is full. Read `estimated_fp_rate()` rather than trusting the capacity someone chose.
- **HyperLogLog:** merge sketches of the same precision to count distinct items across sources: `merge` takes the maximum register by register. Expect a bias of a few percent around 2.5 m, and report the error bar, since 1.04/√m is a standard deviation, not a limit.
- **Count-min sketch:** size it with `with_error`, whose bound is right, and read `new`'s comment as off by a factor e. The estimates are upper bounds, useful for finding heavy items, not for exact counts of light ones.
- **Cuckoo filter:** treat a failed `insert` as a filter that can no longer be trusted and rebuild it larger, since a failure silently removes another item (finding 26). Size it well below 91% full, and check `contains` before inserting input that can repeat.

## Exercises

1. A Bloom filter must hold 1,000,000 items at a false-positive rate of 0.1%. How many bits and hashes does `BloomFilter::new` choose, and how many bytes does IX's filter then take?
2. Why does a HyperLogLog ignore duplicates, and why can a count-min sketch not?
3. In the count-min experiment, the mean overcount is 911, below N/w = 1,000, and yet one item in ten exceeds 1,000. How can both be true?
4. Suggest a change to `CuckooFilter::insert` so that a failed insertion loses nothing, and say what `contains` must then also look at.

<details>
<summary>Solutions</summary>

1. m = ⌈−10⁶ ln 0.001 / (ln 2)²⌉ = 14,377,588 bits and k = ⌈(m/n) ln 2⌉ = ⌈9.97⌉ = 10 hashes. As a `Vec<bool>`, that is 14,377,588 bytes, about 14.4 MB, where packed bits would take about 1.8 MB.
2. HyperLogLog keeps a maximum per register: the same item gives the same register and the same rank, so adding it again cannot raise the maximum. A count-min counter is a sum: adding the same item again adds to it, which is what a frequency count needs.
3. Each estimate is the minimum of three counters. The minimum is usually below its row's mean of about 1,000, which pulls the mean overcount down to 911. But an item exceeds 1,000 whenever its three counters all do, which happens about 0.47³ ≈ 0.1 of the time with these loads.
4. Keep the fingerprint still being carried when the kicks run out in a one-entry "victim" slot, as the authors' reference implementation does, and return false only when that slot is already taken. `contains` and `remove` must then also compare with the victim, and the next successful insertion can try to put it back.

</details>

## Sources

- IX at pinned commit `490c395`: [`bloom.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs), [`hyperloglog.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/hyperloglog.rs), [`count_min.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/count_min.rs), [`cuckoo.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs) and [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/CONTRACTS.md).
- B. H. Bloom, ["Space/time trade-offs in hash coding with allowable errors"](https://doi.org/10.1145/362686.362692), *Communications of the ACM* 13, 1970.
- P. Flajolet, É. Fusy, O. Gandouet and F. Meunier, ["HyperLogLog: the analysis of a near-optimal cardinality estimation algorithm"](https://dmtcs.episciences.org/3545), *Analysis of Algorithms* (AofA 07), DMTCS Proceedings, 2007.
- S. Heule, M. Nunkesser and A. Hall, ["HyperLogLog in practice"](https://research.google/pubs/hyperloglog-in-practice-algorithmic-engineering-of-a-state-of-the-art-cardinality-estimation-algorithm/), EDBT 2013: the bias of the raw estimator at small cardinalities.
- G. Cormode and S. Muthukrishnan, ["An improved data stream summary: the count-min sketch and its applications"](https://doi.org/10.1016/j.jalgor.2003.12.001), *Journal of Algorithms* 55, 2005.
- B. Fan, D. G. Andersen, M. Kaminsky and M. D. Mitzenmacher, ["Cuckoo filter: practically better than Bloom"](https://doi.org/10.1145/2674005.2674994), CoNEXT 2014 ([PDF](https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf)): Algorithms 1 to 3, 95% occupancy with buckets of 4, and the 2b limit on repeated insertions. Their reference implementation, [efficient/cuckoofilter](https://github.com/efficient/cuckoofilter/blob/917583d6abef692dfa8e14453bd77d6e0b61eef3/src/cuckoofilter.h), at `917583d`.
