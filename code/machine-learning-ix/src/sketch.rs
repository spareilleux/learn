//! Lesson 11: counting without counting. The formulas that size and judge a Bloom filter, a count-min sketch
//! and a HyperLogLog, a HyperLogLog written by hand, and the experiments that measure IX's `ix-probabilistic`
//! against them. The experiments live here so that the example prints them and the tests below assert the
//! predictions preregistered in the journal on 2026-09-29, before any of this code ran.

use ix_probabilistic::bloom::BloomFilter;
use ix_probabilistic::count_min::CountMinSketch;
use ix_probabilistic::cuckoo::CuckooFilter;
use ix_probabilistic::hyperloglog::HyperLogLog;
use std::f64::consts::{E, LN_2};

/// Bits a Bloom filter needs for `capacity` items at false-positive rate `fp_rate`: m = −n ln p / (ln 2)².
pub fn bloom_bits(capacity: usize, fp_rate: f64) -> usize {
    (-(capacity as f64) * fp_rate.ln() / (LN_2 * LN_2)).ceil() as usize
}

/// Hash functions for `bits` bits and `capacity` items: k = (m/n) ln 2, rounded up as IX does.
pub fn bloom_hashes(bits: usize, capacity: usize) -> usize {
    ((bits as f64 / capacity as f64) * LN_2).ceil().max(1.0) as usize
}

/// False-positive rate after `inserted` items: (1 − e^(−kn/m))^k, for hashes that behave like random ones.
pub fn bloom_fp_theory(bits: usize, hashes: usize, inserted: usize) -> f64 {
    (1.0 - (-(hashes as f64) * inserted as f64 / bits as f64).exp()).powi(hashes as i32)
}

/// P(X ≥ k) for X ~ Binomial(n, q), summed in log space so that n in the thousands doesn't overflow.
pub fn binomial_tail(n: u64, q: f64, k: u64) -> f64 {
    let ln_choose = |j: u64| ln_factorial(n) - ln_factorial(j) - ln_factorial(n - j);
    (k..=n)
        .map(|j| (ln_choose(j) + j as f64 * q.ln() + (n - j) as f64 * (-q).ln_1p()).exp())
        .sum()
}

fn ln_factorial(n: u64) -> f64 {
    (2..=n).map(|i| (i as f64).ln()).sum()
}

/// splitmix64 (Steele, Lea and Flood): a 64-bit mixer whose output bits look independent, used as the hand
/// HyperLogLog's hash so that it shares nothing with IX's `DefaultHasher`.
pub fn splitmix64(x: u64) -> u64 {
    let mut z = x.wrapping_add(0x9e37_79b9_7f4a_7c15);
    z = (z ^ (z >> 30)).wrapping_mul(0xbf58_476d_1ce4_e5b9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94d0_49bb_1331_11eb);
    z ^ (z >> 31)
}

/// HyperLogLog as Flajolet, Fusy, Gandouet and Meunier describe it: 2^p registers, each keeping the largest
/// rank (position of the first 1 bit) seen among the hashes routed to it, and a harmonic mean of 2^−rank.
pub struct Hll {
    registers: Vec<u8>,
    p: u32,
}

impl Hll {
    pub fn new(p: u32) -> Hll {
        Hll {
            registers: vec![0; 1 << p],
            p,
        }
    }

    /// The low p bits pick the register; the rank is counted in the other 64 − p bits.
    pub fn add_hash(&mut self, hash: u64) {
        let register = (hash & ((1 << self.p) - 1)) as usize;
        let rest = hash >> self.p;
        let rank = (rest.leading_zeros() - self.p + 1) as u8;
        self.registers[register] = self.registers[register].max(rank);
    }

    /// α m² / Σ 2^−M, with linear counting m ln(m / V) below 2.5 m when V registers are still zero.
    pub fn count(&self) -> f64 {
        let m = self.registers.len() as f64;
        let alpha = 0.7213 / (1.0 + 1.079 / m);
        let raw = alpha * m * m
            / self
                .registers
                .iter()
                .map(|&r| 2f64.powi(-(r as i32)))
                .sum::<f64>();
        let zeros = self.registers.iter().filter(|&&r| r == 0).count();
        if raw <= 2.5 * m && zeros > 0 {
            m * (m / zeros as f64).ln()
        } else {
            raw
        }
    }
}

/// IX's `BloomFilter` keeps its hash count private; its serde form carries it.
pub fn ix_hashes(filter: &BloomFilter) -> usize {
    serde_json::to_value(filter).expect("a Bloom filter serializes")["num_hashes"]
        .as_u64()
        .expect("num_hashes is a number") as usize
}

/// One Bloom filter run: insert 0..inserted, then query `queries` integers that were never inserted.
pub struct BloomRun {
    pub bits: usize,
    pub hashes: usize,
    pub false_negatives: usize,
    pub false_positives: usize,
    pub rate: f64,
    pub theory: f64,
    pub ix_estimate: f64,
}

pub fn bloom_experiment(capacity: usize, fp_rate: f64, inserted: u64, queries: u64) -> BloomRun {
    let mut filter = BloomFilter::new(capacity, fp_rate);
    for i in 0..inserted {
        filter.insert(&i);
    }
    let false_negatives = (0..inserted).filter(|i| !filter.contains(i)).count();
    let false_positives = (inserted..inserted + queries)
        .filter(|i| filter.contains(i))
        .count();
    let bits = filter.bit_size();
    let hashes = ix_hashes(&filter);
    BloomRun {
        bits,
        hashes,
        false_negatives,
        false_positives,
        rate: false_positives as f64 / queries as f64,
        theory: bloom_fp_theory(bits, hashes, inserted as usize),
        ix_estimate: filter.estimated_fp_rate(),
    }
}

/// Relative errors of a cardinality estimator over `sets` disjoint sets of `per_set` consecutive integers.
pub struct HllRun {
    pub rms: f64,
    pub mean: f64,
    pub worst: f64,
}

impl HllRun {
    fn of(errors: &[f64]) -> HllRun {
        let n = errors.len() as f64;
        HllRun {
            rms: (errors.iter().map(|e| e * e).sum::<f64>() / n).sqrt(),
            mean: errors.iter().sum::<f64>() / n,
            worst: errors.iter().fold(0.0, |w: f64, e| w.max(e.abs())),
        }
    }
}

pub fn hll_experiment_ix(p: usize, sets: u64, per_set: u64) -> HllRun {
    let errors: Vec<f64> = (0..sets)
        .map(|t| {
            let mut sketch = HyperLogLog::new(p);
            for i in t * per_set..(t + 1) * per_set {
                sketch.add(&i);
            }
            sketch.count() / per_set as f64 - 1.0
        })
        .collect();
    HllRun::of(&errors)
}

pub fn hll_experiment_hand(p: u32, sets: u64, per_set: u64) -> HllRun {
    let errors: Vec<f64> = (0..sets)
        .map(|t| {
            let mut sketch = Hll::new(p);
            for i in t * per_set..(t + 1) * per_set {
                sketch.add_hash(splitmix64(i));
            }
            sketch.count() / per_set as f64 - 1.0
        })
        .collect();
    HllRun::of(&errors)
}

/// A count-min sketch fed `items` distinct integers `repeats` times each, and how far each estimate overshoots.
pub struct CountMinRun {
    pub total: u64,
    pub underestimates: usize,
    pub mean_overcount: f64,
    pub max_overcount: u64,
    /// Share of items whose overcount exceeds N / width, the bound `CountMinSketch::new` documents
    pub above_doc_bound: f64,
    /// Share of items whose overcount exceeds e N / width, the bound of Cormode and Muthukrishnan
    pub above_cm_bound: f64,
}

pub fn count_min_experiment(width: usize, depth: usize, items: u64, repeats: u64) -> CountMinRun {
    let mut sketch = CountMinSketch::new(width, depth);
    for _ in 0..repeats {
        for i in 0..items {
            sketch.add(&i);
        }
    }
    let total = sketch.total_count();
    let doc_bound = total as f64 / width as f64;
    let cm_bound = E * doc_bound;
    let estimates: Vec<u64> = (0..items).map(|i| sketch.estimate(&i)).collect();
    let overcounts: Vec<u64> = estimates
        .iter()
        .map(|&e| e.saturating_sub(repeats))
        .collect();
    let share =
        |bound: f64| overcounts.iter().filter(|&&o| o as f64 > bound).count() as f64 / items as f64;
    CountMinRun {
        total,
        underestimates: estimates.iter().filter(|&&e| e < repeats).count(),
        mean_overcount: overcounts.iter().sum::<u64>() as f64 / items as f64,
        max_overcount: overcounts.iter().copied().max().unwrap_or(0),
        above_doc_bound: share(doc_bound),
        above_cm_bound: share(cm_bound),
    }
}

/// A cuckoo filter filled with 0, 1, 2, … until the first insert fails, and what it still finds afterwards.
pub struct CuckooRun {
    pub slots: usize,
    /// The integer whose insert failed first
    pub first_failure: Option<u64>,
    pub load_at_failure: f64,
    /// Integers inserted successfully before that failure that `contains` no longer finds
    pub lost: Vec<u64>,
    /// Whether `contains` finds the integer whose insert failed
    pub failed_item_found: bool,
}

pub fn cuckoo_experiment(capacity: usize, limit: u64) -> (CuckooRun, CuckooFilter) {
    let mut filter = CuckooFilter::new(capacity);
    let slots = (capacity / 4).next_power_of_two().max(1) * 4;
    let mut first_failure = None;
    for i in 0..limit {
        if !filter.insert(&i) {
            first_failure = Some(i);
            break;
        }
    }
    let inserted = first_failure.unwrap_or(limit);
    let lost = (0..inserted).filter(|i| !filter.contains(i)).collect();
    let run = CuckooRun {
        slots,
        first_failure,
        load_at_failure: filter.load_factor(),
        lost,
        failed_item_found: first_failure.is_some_and(|i| filter.contains(&i)),
    };
    (run, filter)
}

/// Two filters fed the same sequence: whether they fail at the same insert, and on how many of `probes`
/// integers their `contains` answers differ.
pub fn cuckoo_twice(capacity: usize, limit: u64, probes: u64) -> (bool, usize) {
    let (a, fa) = cuckoo_experiment(capacity, limit);
    let (b, fb) = cuckoo_experiment(capacity, limit);
    let disagreements = (0..probes)
        .filter(|i| fa.contains(i) != fb.contains(i))
        .count();
    (a.first_failure == b.first_failure, disagreements)
}

#[cfg(test)]
mod tests {
    use super::*;

    // The hand formulas and IX agree on the filter's size before any prediction is tested.
    #[test]
    fn hand_sizing_matches_ix() {
        let bits = bloom_bits(10_000, 0.01);
        assert_eq!(bits, 95_851);
        assert_eq!(bloom_hashes(bits, 10_000), 7);
        let filter = BloomFilter::new(10_000, 0.01);
        assert_eq!(filter.bit_size(), bits);
        assert_eq!(ix_hashes(&filter), 7);
    }

    #[test]
    fn binomial_tail_of_a_fair_coin() {
        // P(X ≥ 6) for ten fair tosses is 386/1024
        assert!((binomial_tail(10, 0.5, 6) - 386.0 / 1024.0).abs() < 1e-12);
    }

    // P1, preregistered 2026-09-29: at capacity, the rate lies in [0.00909, 0.01098].
    #[test]
    fn p1_bloom_at_capacity() {
        let run = bloom_experiment(10_000, 0.01, 10_000, 100_000);
        assert_eq!(run.false_negatives, 0);
        assert!((0.00909..=0.01098).contains(&run.rate), "rate {}", run.rate);
    }

    // P2, preregistered 2026-09-29: at twice the capacity, the rate lies in [0.1540, 0.1609].
    #[test]
    fn p2_bloom_at_twice_capacity() {
        let run = bloom_experiment(10_000, 0.01, 20_000, 100_000);
        assert_eq!(run.false_negatives, 0);
        assert!((0.1540..=0.1609).contains(&run.rate), "rate {}", run.rate);
    }

    // P3, preregistered 2026-09-29: RMS relative error in [0.0256, 0.0394], mean within ±0.00975, for IX and by hand.
    #[test]
    fn p3_hyperloglog_error() {
        for (who, run) in [
            ("IX", hll_experiment_ix(10, 100, 100_000)),
            ("hand", hll_experiment_hand(10, 100, 100_000)),
        ] {
            assert!(
                (0.0256..=0.0394).contains(&run.rms),
                "{who}: rms {}",
                run.rms
            );
            assert!(run.mean.abs() <= 0.00975, "{who}: mean {}", run.mean);
        }
    }

    // P4, preregistered 2026-09-29: more than e^-3 of the items exceed N/width, in [0.07, 0.20];
    // fewer than e^-3 exceed e N/width.
    #[test]
    fn p4_count_min_bounds() {
        let run = count_min_experiment(100, 3, 10_000, 10);
        let failure = (-3f64).exp();
        assert_eq!(run.underestimates, 0);
        assert!(run.above_doc_bound > failure, "{}", run.above_doc_bound);
        assert!(
            (0.07..=0.20).contains(&run.above_doc_bound),
            "{}",
            run.above_doc_bound
        );
        assert!(run.above_cm_bound < failure, "{}", run.above_cm_bound);
    }

    // P5, preregistered 2026-09-29: the first failed insert comes at a load factor of at least 0.90.
    #[test]
    fn p5_cuckoo_load_at_first_failure() {
        let (run, _) = cuckoo_experiment(4096, 10_000);
        assert!(run.first_failure.is_some());
        assert!(run.load_at_failure >= 0.90, "load {}", run.load_at_failure);
    }

    // P6, preregistered 2026-09-29: after the first failure, at least one earlier item is no longer found.
    #[test]
    fn p6_cuckoo_loses_an_item_when_an_insert_fails() {
        let (run, _) = cuckoo_experiment(4096, 10_000);
        assert!(!run.lost.is_empty());
    }

    // P7, preregistered 2026-09-29: two filters fed the same sequence behave identically.
    #[test]
    fn p7_cuckoo_is_deterministic() {
        assert_eq!(cuckoo_twice(4096, 10_000, 100_000), (true, 0));
    }
}
