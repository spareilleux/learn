//! Lesson 11: Bloom filters, HyperLogLog, count-min and cuckoo filters from IX's `ix-probabilistic`,
//! measured against the formulas that size them and against the predictions preregistered in the journal.

use ix_probabilistic::count_min::CountMinSketch;
use ix_probabilistic::cuckoo::CuckooFilter;
use ix_probabilistic::hyperloglog::HyperLogLog;
use machine_learning_ix::sketch::*;
use std::f64::consts::E;

fn main() {
    println!("== Bloom filter: new(10000, 0.01)");
    let bits = bloom_bits(10_000, 0.01);
    println!(
        "  hand sizing: m = {bits} bits, k = {} hashes",
        bloom_hashes(bits, 10_000)
    );
    for inserted in [10_000u64, 20_000] {
        let run = bloom_experiment(10_000, 0.01, inserted, 100_000);
        println!(
            "  {inserted} inserted, IX m = {}, k = {}: {} false negatives, {} false positives in 100000 queries, rate {:.5}; theory {:.5}; estimated_fp_rate {:.5}",
            run.bits,
            run.hashes,
            run.false_negatives,
            run.false_positives,
            run.rate,
            run.theory,
            run.ix_estimate
        );
    }

    println!("\n== HyperLogLog, p = 10 (1024 registers): 100 disjoint sets of 100000 integers");
    println!(
        "  predicted standard error 1.04 / sqrt(1024) = {:.4}",
        1.04 / 32.0
    );
    for (who, run) in [
        ("IX, DefaultHasher", hll_experiment_ix(10, 100, 100_000)),
        ("hand, splitmix64 ", hll_experiment_hand(10, 100, 100_000)),
    ] {
        println!(
            "  {who}: RMS relative error {:.4}, mean {:.4}, worst {:.4}",
            run.rms, run.mean, run.worst
        );
    }

    println!("\n== HyperLogLog across cardinalities, p = 10, 100 sets each (not preregistered)");
    for n in [500u64, 2_000, 2_560, 3_000, 4_000, 6_000, 10_000, 100_000] {
        let ix = hll_experiment_ix(10, 100, n);
        let hand = hll_experiment_hand(10, 100, n);
        println!(
            "  n = {n:>6}: IX mean {:>7.4}, RMS {:.4}; hand mean {:>7.4}, RMS {:.4}",
            ix.mean, ix.rms, hand.mean, hand.rms
        );
    }
    let standard = HyperLogLog::standard();
    println!(
        "  HyperLogLog::standard(): memory_bytes {}, error_rate {:.4}",
        standard.memory_bytes(),
        standard.error_rate()
    );

    println!("\n== count-min sketch: new(100, 3), 10000 integers added 10 times each");
    let run = count_min_experiment(100, 3, 10_000, 10);
    let doc_bound = run.total as f64 / 100.0;
    let model = binomial_tail(9_999, 0.01, 101).powi(3);
    println!(
        "  N = {}; underestimates {}; mean overcount {:.1}; max overcount {}",
        run.total, run.underestimates, run.mean_overcount, run.max_overcount
    );
    println!(
        "  share above N/width = {doc_bound:.0}: {:.4} (binomial model {model:.4}; the doc allows {:.4})",
        run.above_doc_bound,
        (-3f64).exp()
    );
    println!(
        "  share above e N/width = {:.0}: {:.4}",
        E * doc_bound,
        run.above_cm_bound
    );
    let sized = serde_json::to_value(CountMinSketch::with_error(0.01, 0.05)).expect("serializes");
    println!(
        "  with_error(0.01, 0.05): width {}, depth {}",
        sized["width"], sized["depth"]
    );

    println!("\n== cuckoo filter: new(4096), integers 0, 1, 2, ... until an insert fails");
    let (run, filter) = cuckoo_experiment(4096, 10_000);
    let failed = run.first_failure.expect("the filter fills up");
    println!(
        "  {} slots; first failure inserting {failed}, load factor {:.4}",
        run.slots, run.load_at_failure
    );
    println!(
        "  earlier integers no longer found: {} {:?}; the failed integer found: {}",
        run.lost.len(),
        run.lost,
        run.failed_item_found
    );
    let probes = 100_000u64;
    let false_positives = (1_000_000..1_000_000 + probes)
        .filter(|i| filter.contains(i))
        .count();
    println!(
        "  false positives on {probes} integers never inserted: {false_positives}, rate {:.5}",
        false_positives as f64 / probes as f64
    );
    let (same_failure, disagreements) = cuckoo_twice(4096, 10_000, 100_000);
    println!(
        "  a second filter on the same sequence: same failure {same_failure}, contains disagreements {disagreements}"
    );

    println!("\n== cuckoo filter: the same integer inserted again and again");
    let mut repeated = CuckooFilter::new(4096);
    let results: Vec<bool> = (0..10).map(|_| repeated.insert(&42u64)).collect();
    println!(
        "  insert(42) ten times: {results:?}; len {}",
        repeated.len()
    );
}
