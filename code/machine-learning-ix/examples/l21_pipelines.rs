//! Lesson 21: IX's `ix-pipeline` — the executor documented as parallel, the cache key, the final outputs and a
//! missing field, the lock file's hash and `lower` without skills — then the steps of the `ix_ml_pipeline` MCP tool
//! replayed with IX's functions: the macro average, lesson 1's three items to verify, and the order ML.NET's
//! `MLContext` follows written as an `ix-pipeline` DAG. The tool itself runs in `l21_mcp`, on the author's machine.

use machine_learning_ix::data::load_builds;
use machine_learning_ix::data_path;
use machine_learning_ix::fmt_vec;
use machine_learning_ix::pipeline::{
    SEED, Scaling, TEST_RATIO, auto_choice, diamond, ix_macro, leak_free_dag, lock_hashes,
    lower_scaffold, read_field, replay_knn, replay_regression, same_bits, shared_cache, tool_macro,
    two_blobs,
};
use ndarray::{Array1, Array2, array};
use std::time::Duration;

/// A number with fixed decimals, never `-0.000`
fn fixed(x: f64, decimals: usize) -> String {
    fmt_vec([x], decimals).trim_matches(['[', ']']).to_string()
}

fn yes(b: bool) -> &'static str {
    if b { "yes" } else { "no" }
}

fn blobs(labels: [f64; 2]) -> (Array2<f64>, Array1<f64>) {
    let rows = two_blobs(labels);
    let x = Array2::from_shape_fn((rows.len(), 2), |(i, j)| rows[i][j]);
    let y = rows.iter().map(|r| r[2]).collect();
    (x, y)
}

fn main() {
    println!("== P1, a diamond: load -> a and b -> report, a and b sleeping 50 ms each");
    let d = diamond(Duration::from_millis(50));
    println!("  parallel_levels: {:?}", d.levels);
    println!(
        "  compute functions run: {}, all on the thread that called execute: {}",
        d.threads.len(),
        yes(d.threads.iter().all(|(_, t)| *t == d.caller))
    );
    println!(
        "  total_duration at least 100 ms: {}; report = {}",
        yes(d.result.total_duration >= Duration::from_millis(100)),
        d.result.output("report").unwrap()
    );

    println!(
        "\n== P2, one cache shared by two pipelines: f(x) = x + 1, then f(x) = 2x, on value = 10"
    );
    for (run, (output, hits)) in ["x + 1", "2x"].iter().zip(shared_cache()) {
        println!("  {run}: output {output}, cache hits {hits}");
    }

    println!("\n== P3, final_outputs and input_field");
    let d = diamond(Duration::ZERO);
    println!(
        "  final_outputs on the diamond: {} entries, for 1 leaf",
        d.result.final_outputs().len()
    );
    println!(
        "  field \"missing\" of {{\"a\": 1}}: {}; field \"a\": {}",
        read_field("missing"),
        read_field("a")
    );

    println!("\n== P4, the lock file's args_hash, and lower without a linked skill");
    let h = lock_hashes();
    println!("  canonical args: {}", h.canonical);
    println!("  args_hash:                        {}", h.args_hash);
    println!(
        "  DefaultHasher of that string:     {}  same: {}",
        h.default_hasher,
        yes(h.args_hash == h.default_hasher)
    );
    println!(
        "  FNV-1a 64 of the same bytes:      {}  same: {}",
        h.fnv1a64,
        yes(h.args_hash == h.fnv1a64)
    );
    println!(
        "  lower(PipelineSpec::scaffold(\"demo\")): {}",
        lower_scaffold()
    );

    println!("\n== P5, labels 1 and 2, all predicted right");
    let y = array![1usize, 2, 1, 2, 2];
    let [p, r, f] = tool_macro(&y, &y, 3);
    println!("  the tool's loop over classes 0 to 2: precision {p}, recall {r}, f1 {f}");
    let [p, r, f] = ix_macro(&y, &y);
    println!("  precision_avg, recall_avg, f1_avg with Average::Macro: {p}, {r}, {f}");
    let y = array![0usize, 1, 0, 1];
    let [p, r, f] = tool_macro(&y, &y, 2);
    println!("  labels 0 and 1, the tool's loop over classes 0 and 1: {p}, {r}, {f}");
    for labels in [[1.0, 2.0], [0.0, 1.0]] {
        let (x, y) = blobs(labels);
        let (task, model) = auto_choice(&x, &y);
        let k = replay_knn(&x, &y, 5, Scaling::None, 0.3, SEED);
        let mut present = k.predictions.clone();
        present.sort();
        present.dedup();
        println!(
            "  P5's call replayed, labels {} and {}: {task}, {model}, {} training and {} test rows, classes among the test predictions {:?}, accuracy {}, macro {:?}",
            labels[0], labels[1], k.train, k.test, present, k.accuracy, k.macro_scores
        );
    }

    let b = load_builds(data_path("builds.csv"));
    println!(
        "\n== P6, lesson 1's items replayed on builds.csv: pages -> build_seconds, {} rows",
        b.seconds.len()
    );
    let mut distinct: Vec<i64> = b.seconds.iter().map(|&s| s as i64).collect();
    distinct.sort();
    distinct.dedup();
    let (task, model) = auto_choice(&b.pages, &b.seconds);
    println!(
        "  build_seconds: {} distinct values, all whole: {}; task and model on auto: {task}, {model}",
        distinct.len(),
        yes(b.seconds.iter().all(|s| s.fract() == 0.0))
    );
    let k = replay_knn(&b.pages, &b.seconds, 5, Scaling::None, TEST_RATIO, SEED);
    println!(
        "  knn, k = 5, {} training and {} test rows, {} classes counted: accuracy {}, precision {}, recall {}, f1 {}",
        k.train,
        k.test,
        k.n_classes,
        fixed(k.accuracy, 6),
        fixed(k.macro_scores[0], 6),
        fixed(k.macro_scores[1], 6),
        fixed(k.macro_scores[2], 6)
    );
    let all = replay_regression(&b.pages, &b.seconds, Scaling::AllRows);
    let train = replay_regression(&b.pages, &b.seconds, Scaling::TrainingRows);
    for (name, r) in [
        ("scaler on all rows (the tool)", &all),
        ("scaler on the training rows", &train),
    ] {
        println!(
            "  linear regression, {name}: mse {}, rmse {}, r2 {}",
            fixed(r.mse, 4),
            fixed(r.rmse, 4),
            fixed(r.r_squared, 6)
        );
    }
    let gap = all
        .numbers()
        .iter()
        .zip(train.numbers())
        .map(|(a, b)| (a - b).abs())
        .fold(0.0, f64::max);
    println!(
        "  the two replays' 13 predictions and 3 metrics: largest difference below 1e-9: {}",
        yes(gap < 1e-9)
    );

    println!("\n== The order ML.NET's MLContext follows, as an ix-pipeline DAG");
    let (levels, dag) = leak_free_dag(&b.pages, &b.seconds);
    println!("  levels: {levels:?}");
    println!(
        "  the same 16 numbers as the training-rows replay, bit for bit: {} of 16",
        same_bits(&dag.numbers(), &train.numbers())
    );
}
