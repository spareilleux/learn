//! Lesson 21 through IX's MCP server: `IX_MCP=<path of ix-mcp> cargo run --release --bin l21_mcp`. The server is
//! `ix-agent`'s binary built at the pinned commit outside the repository, so CI doesn't run this program; the lesson
//! quotes one run on the author's machine, saved in `local/l21_mcp.txt`. Each prediction gets a server process of its
//! own, except P7's parts, which share one on purpose.

use machine_learning_ix::mcp::{self, Reply, Server, UNLISTED, number};
use machine_learning_ix::pipeline::same_bits;

fn yes(b: bool) -> &'static str {
    if b { "yes" } else { "no" }
}

fn start() -> Server {
    let exe = mcp::ix_mcp().expect("set IX_MCP to the ix-mcp binary built at the pinned commit");
    Server::start(&exe).expect("ix-mcp starts and answers initialize")
}

/// The first stderr line that contains `needle`, trimmed
fn line_with(stderr: &str, needle: &str) -> String {
    stderr
        .lines()
        .find(|l| l.contains(needle))
        .map_or("(none)".into(), |l| l.trim().to_string())
}

fn main() {
    let mut s = start();
    let tools = s.tools(mcp::ANSWER).unwrap_or_default();
    println!(
        "== ix-mcp at the pinned commit: {} tools listed",
        tools.len()
    );

    println!("\n== P5 through the tool: 20 inline rows, test ratio 0.3, task and model on auto");
    for (labels, counted) in [([1.0, 2.0], 3), ([0.0, 1.0], 2)] {
        let p = mcp::p5_tool(&mut s, labels);
        let k_over_n = p.classes_in_test as f64 / counted as f64;
        println!(
            "  labels {} and {}: {}; model {}, accuracy {}, classes among the test predictions {}",
            labels[0],
            labels[1],
            p.reply.summary(),
            p.model,
            p.accuracy,
            p.classes_in_test
        );
        println!(
            "    precision {}, recall {}, f1 {}; each equal to k/{counted} = {k_over_n}: {}",
            p.scores[0],
            p.scores[1],
            p.scores[2],
            yes(p.scores.iter().all(|v| v.to_bits() == k_over_n.to_bits()))
        );
    }
    drop(s);

    println!("\n== P6, lesson 1's three items to verify, through the tool");
    let mut s = start();
    let p = mcp::p6(&mut s);
    println!("  (a) builds.csv as it is: {}", p.raw.summary());
    let d = p.defaults.json();
    println!(
        "  (b) pages and build_seconds, defaults: task {}, model {}, {} training and {} test rows",
        d["task"], d["model"], d["split"]["train"], d["split"]["test"]
    );
    let (tool, replay) = (p.defaults_numbers(), p.defaults_replay_numbers());
    println!("      tool:   accuracy, precision, recall, f1 = {tool:?}");
    println!("      replay: accuracy, precision, recall, f1 = {replay:?}");
    println!(
        "      same bits: {} of {}",
        same_bits(&tool, &replay),
        replay.len()
    );
    let r = p.regress.json();
    println!(
        "  (c) task regress, normalize on: {}; model {}, {} predictions returned",
        p.regress.summary(),
        r["model"],
        p.regress_numbers.len() - 3
    );
    let (all, train) = (p.all_rows.numbers(), p.training_rows.numbers());
    println!(
        "      same bits as the replay that fits the scaler on all 65 rows: {} of {}",
        same_bits(&p.regress_numbers, &all),
        all.len()
    );
    println!(
        "      same bits as the replay that splits first and fits it on the 52 training rows: {} of {}",
        same_bits(&p.regress_numbers, &train),
        train.len()
    );
    let gap = p
        .regress_numbers
        .iter()
        .zip(&train)
        .map(|(a, b)| (a - b).abs())
        .fold(0.0, f64::max);
    println!("      largest difference from the training-rows replay: {gap:e}");
    println!(
        "      mse {}, rmse {}, r2 {}",
        number(p.regress.text(), "mse"),
        number(p.regress.text(), "rmse"),
        number(p.regress.text(), "r_squared")
    );
    drop(s);

    println!("\n== P7, one server: a persisted knn, then a prediction that panics");
    let mut s = start();
    let p = mcp::p7(&mut s);
    println!(
        "  (a) P5's rows persisted as l21-knn: {}, persisted {}",
        p.knn_persist.summary(),
        p.knn_persist.json()["persisted"]
    );
    println!(
        "      ix_ml_predict on l21-knn: {}",
        p.knn_predict.summary()
    );
    let pca = p.pca_persist.json();
    println!(
        "  (b) 10 rows of 3 features, normalize, pca_components 1, persisted as l21-pca: {}, data_shape {}",
        p.pca_persist.summary(),
        pca["data_shape"]
    );
    println!(
        "      ix_ml_predict on a row of 3 features: {}",
        p.pca_predict.summary()
    );
    println!(
        "      stderr: {}",
        line_with(&p.stderr_after_predict, "not compatible")
    );
    println!(
        "  (c) tools/list afterwards: {}",
        p.tools_after
            .map_or("no response".into(), |n| format!("{n} tools"))
    );
    println!(
        "      P5's valid ix_ml_pipeline call afterwards: {}",
        p.valid_call_after.summary()
    );
    println!(
        "      stderr: {}",
        line_with(&p.stderr_after_call, "poisoned")
    );
    println!(
        "      panics on stderr: {}",
        p.stderr_after_call.matches("panicked at").count()
    );
    drop(s);

    println!("\n== P8, a fresh server: the loop detector, then the approval policy");
    let mut s = start();
    let p = mcp::p8(&mut s);
    for (seed, reply) in (1..).zip(&p.repeated) {
        let shown = match reply {
            Reply::Ok(_) => "ok".to_string(),
            other => other.summary(),
        };
        println!("  ix_ml_pipeline, seed {seed}: {shown}");
    }
    println!(
        "  ix_ml_predict on an unknown key: {}",
        p.predict_after.summary()
    );
    let listed: Vec<&str> = UNLISTED
        .iter()
        .copied()
        .filter(|t| p.tools.iter().any(|n| n == t))
        .collect();
    println!(
        "  tools/list: {} tools; of the six in neither approval list, listed: {}",
        p.tools.len(),
        listed.len()
    );
    println!("  ix_petri_analyze: {}", p.petri.summary());
}
