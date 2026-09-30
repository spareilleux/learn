//! Lesson 21's predictions that need IX's MCP server: `IX_MCP=<path of ix-mcp> cargo test --release --test l21_mcp
//! -- --ignored`. The server is built at the pinned commit outside the repository, so CI skips them. Each test
//! starts a server process of its own.

use machine_learning_ix::mcp::{self, Reply, Server, UNLISTED};
use machine_learning_ix::pipeline::same_bits;

fn server() -> Server {
    let exe = mcp::ix_mcp().expect("set IX_MCP to the ix-mcp binary built at the pinned commit");
    Server::start(&exe).expect("ix-mcp starts and answers initialize")
}

fn err_containing(reply: &Reply, needles: &[&str]) {
    match reply {
        Reply::Err(t) => {
            for n in needles {
                assert!(t.contains(n), "{n:?} not in {t:?}");
            }
        }
        other => panic!("expected an error, got {other:?}"),
    }
}

#[test]
#[ignore = "needs IX's MCP server, named by IX_MCP"]
fn p5_the_tool_averages_over_classes_that_are_not_there() {
    let mut s = server();
    for (labels, counted) in [([1.0, 2.0], 3.0), ([0.0, 1.0], 2.0)] {
        let p = mcp::p5_tool(&mut s, labels);
        assert!(matches!(p.reply, Reply::Ok(_)), "{:?}", p.reply);
        assert_eq!(p.model, "knn");
        assert_eq!(p.accuracy, 1.0);
        let k_over_n = p.classes_in_test as f64 / counted;
        assert_eq!(p.scores.map(f64::to_bits), [k_over_n.to_bits(); 3]);
    }
}

#[test]
#[ignore = "needs IX's MCP server, named by IX_MCP"]
fn p6_lesson_1s_three_items_run_through_the_tool() {
    let mut s = server();
    let p = mcp::p6(&mut s);
    err_containing(&p.raw, &["All rows contain NaN values"]);
    let d = p.defaults.json();
    assert_eq!(d["task"], "classify");
    assert_eq!(d["model"], "knn");
    assert_eq!(
        (d["split"]["train"].as_u64(), d["split"]["test"].as_u64()),
        (Some(52), Some(13))
    );
    assert_eq!(
        same_bits(&p.defaults_numbers(), &p.defaults_replay_numbers()),
        4
    );
    assert_eq!(p.regress_numbers.len(), 16);
    assert_eq!(same_bits(&p.regress_numbers, &p.all_rows.numbers()), 16);
    assert!(same_bits(&p.regress_numbers, &p.training_rows.numbers()) < 16);
}

#[test]
#[ignore = "needs IX's MCP server, named by IX_MCP"]
fn p7_a_persisted_knn_and_a_panic_that_poisons_the_chain() {
    let mut s = server();
    let p = mcp::p7(&mut s);
    assert_eq!(p.knn_persist.json()["persisted"], true);
    err_containing(
        &p.knn_predict,
        &["Prediction not supported for algorithm 'knn'"],
    );
    assert_eq!(p.pca_persist.json()["data_shape"]["features"], 1);
    assert_eq!(p.pca_predict, Reply::Silent);
    assert!(
        p.stderr_after_predict
            .contains("are not compatible for matrix multiplication")
    );
    assert!(p.tools_after.is_some());
    assert_eq!(p.valid_call_after, Reply::Silent);
    assert!(
        p.stderr_after_call
            .contains("middleware chain mutex poisoned")
    );
}

#[test]
#[ignore = "needs IX's MCP server, named by IX_MCP"]
fn p8_the_loop_detector_and_the_approval_policy_come_before_the_skill() {
    let mut s = server();
    let p = mcp::p8(&mut s);
    assert!(
        p.repeated[..10].iter().all(|r| matches!(r, Reply::Ok(_))),
        "{:?}",
        &p.repeated[..10]
    );
    err_containing(
        &p.repeated[10],
        &[
            "ix_loop_detect: circuit breaker tripped on tool 'ix_ml_pipeline'",
            "11 calls",
        ],
    );
    err_containing(&p.predict_after, &["No persisted model found for key"]);
    for t in UNLISTED {
        assert!(p.tools.iter().any(|n| n == t), "{t} not listed");
    }
    err_containing(
        &p.petri,
        &[
            "ix_approval: action blocked (ApprovalRequired)",
            "tier: tier_three",
        ],
    );
}
