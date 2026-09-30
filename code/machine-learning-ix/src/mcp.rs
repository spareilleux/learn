//! Lesson 21: a small client for IX's MCP server, `ix-mcp`, and the runs that measure `ix_ml_pipeline` and
//! `ix_ml_predict` through it. The server is the binary of `ix-agent`, which the course doesn't link: it is built
//! at the pinned commit outside the repository and named by the `IX_MCP` environment variable. Only the `l21_mcp`
//! program and the ignored tests of `tests/l21_mcp.rs` start it.
//!
//! The transport is MCP's stdio one: one JSON-RPC message per line on the server's stdin and stdout, its log on
//! stderr (<https://modelcontextprotocol.io/specification/2024-11-05/basic/transports>).

use crate::pipeline::{self, ClassifyReplay, RegressReplay, Scaling};
use ndarray::{Array1, Array2};
use serde_json::{Value, json};
use std::io::{BufRead, BufReader, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Child, ChildStdin, Command, Stdio};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc::{Receiver, RecvTimeoutError, channel};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};

/// How long an answer may take before a call counts as unanswered, for the calls expected to answer
pub const ANSWER: Duration = Duration::from_secs(30);
/// How long to wait for an answer the prediction says never comes
pub const SILENCE: Duration = Duration::from_secs(10);

/// The server binary named by `IX_MCP`, if any
pub fn ix_mcp() -> Option<PathBuf> {
    std::env::var_os("IX_MCP").map(PathBuf::from)
}

/// What a `tools/call` came back with
#[derive(Debug, Clone, PartialEq)]
pub enum Reply {
    /// The tool's result, the pretty-printed JSON text the server sends
    Ok(String),
    /// `isError`, or a JSON-RPC error: the message
    Err(String),
    /// Nothing before the deadline
    Silent,
}

impl Reply {
    pub fn text(&self) -> &str {
        match self {
            Reply::Ok(t) | Reply::Err(t) => t,
            Reply::Silent => "",
        }
    }

    pub fn json(&self) -> Value {
        match self {
            Reply::Ok(t) => serde_json::from_str(t).unwrap_or(Value::Null),
            _ => Value::Null,
        }
    }

    /// One line for a report: `ok`, `error: …` or `no response`
    pub fn summary(&self) -> String {
        match self {
            Reply::Ok(_) => "ok".into(),
            Reply::Err(t) => format!("error: {t}"),
            Reply::Silent => "no response".into(),
        }
    }
}

/// One `ix-mcp` process, in a directory of its own, killed and removed on drop
pub struct Server {
    child: Child,
    stdin: ChildStdin,
    messages: Receiver<Value>,
    stderr: Arc<Mutex<String>>,
    next_id: u64,
    dir: PathBuf,
}

static STARTED: AtomicUsize = AtomicUsize::new(0);

impl Server {
    /// Starts the server and runs MCP's handshake, `initialize` then `notifications/initialized`
    pub fn start(exe: &Path) -> std::io::Result<Server> {
        let dir = std::env::temp_dir().join(format!(
            "l21-mcp-{}-{}",
            std::process::id(),
            STARTED.fetch_add(1, Ordering::SeqCst)
        ));
        std::fs::create_dir_all(&dir)?;
        let mut child = Command::new(exe)
            .current_dir(&dir)
            .env_remove("IX_MCP_SCOPE")
            .env_remove("IX_SESSION_LOG")
            .env_remove("RUST_BACKTRACE")
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()?;
        let stdin = child.stdin.take().expect("piped");
        let stdout = child.stdout.take().expect("piped");
        let mut err = child.stderr.take().expect("piped");
        let (tx, messages) = channel();
        thread::spawn(move || {
            for line in BufReader::new(stdout).lines().map_while(Result::ok) {
                if let Ok(message) = serde_json::from_str::<Value>(&line)
                    && tx.send(message).is_err()
                {
                    break;
                }
            }
        });
        let stderr = Arc::new(Mutex::new(String::new()));
        let sink = stderr.clone();
        thread::spawn(move || {
            let mut buf = [0u8; 4096];
            while let Ok(n) = err.read(&mut buf) {
                if n == 0 {
                    break;
                }
                sink.lock()
                    .unwrap()
                    .push_str(&String::from_utf8_lossy(&buf[..n]));
            }
        });
        let mut server = Server {
            child,
            stdin,
            messages,
            stderr,
            next_id: 0,
            dir,
        };
        let hello = json!({
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": { "name": "machine-learning-ix-l21", "version": "0.1.0" },
        });
        if server.request("initialize", hello, ANSWER).is_none() {
            return Err(std::io::Error::other("no answer to initialize"));
        }
        server.send(json!({ "jsonrpc": "2.0", "method": "notifications/initialized" }))?;
        Ok(server)
    }

    /// The server's working directory, where a CSV must be for a relative path
    pub fn dir(&self) -> &Path {
        &self.dir
    }

    /// Everything the server wrote on stderr so far
    pub fn stderr(&self) -> String {
        self.stderr.lock().unwrap().clone()
    }

    fn send(&mut self, message: Value) -> std::io::Result<()> {
        writeln!(self.stdin, "{message}")?;
        self.stdin.flush()
    }

    /// Sends a request and waits for the response with its id; `None` if none comes before `timeout`
    pub fn request(&mut self, method: &str, params: Value, timeout: Duration) -> Option<Value> {
        self.next_id += 1;
        let id = self.next_id;
        self.send(json!({ "jsonrpc": "2.0", "id": id, "method": method, "params": params }))
            .ok()?;
        let deadline = Instant::now() + timeout;
        loop {
            let left = deadline.saturating_duration_since(Instant::now());
            match self.messages.recv_timeout(left) {
                Ok(message) if message["id"] == json!(id) => return Some(message),
                Ok(_) => continue,
                Err(RecvTimeoutError::Timeout | RecvTimeoutError::Disconnected) => return None,
            }
        }
    }

    /// `tools/call`
    pub fn call(&mut self, tool: &str, arguments: Value, timeout: Duration) -> Reply {
        let Some(message) = self.request(
            "tools/call",
            json!({ "name": tool, "arguments": arguments }),
            timeout,
        ) else {
            return Reply::Silent;
        };
        if let Some(error) = message.get("error") {
            return Reply::Err(error["message"].as_str().unwrap_or_default().to_string());
        }
        let result = &message["result"];
        let text = result["content"][0]["text"]
            .as_str()
            .unwrap_or_default()
            .to_string();
        if result["isError"] == json!(true) {
            Reply::Err(text)
        } else {
            Reply::Ok(text)
        }
    }

    /// `tools/list`: the tool names, `None` without an answer
    pub fn tools(&mut self, timeout: Duration) -> Option<Vec<String>> {
        let message = self.request("tools/list", json!({}), timeout)?;
        let tools = message["result"]["tools"].as_array()?;
        Some(
            tools
                .iter()
                .filter_map(|t| t["name"].as_str().map(str::to_string))
                .collect(),
        )
    }
}

impl Drop for Server {
    fn drop(&mut self) {
        let _ = self.child.kill();
        let _ = self.child.wait();
        let _ = std::fs::remove_dir_all(&self.dir);
    }
}

/// The numbers after `"key":` in the server's text, as written: one, or every one of an array. `serde_json`
/// parses a float without the `float_roundtrip` feature to within one unit in the last place; the standard
/// library's `parse` rounds correctly, so the bits compared are the bits the server wrote.
pub fn numbers(text: &str, key: &str) -> Vec<f64> {
    let needle = format!("\"{key}\":");
    let Some(at) = text.find(&needle) else {
        return vec![];
    };
    let rest = text[at + needle.len()..].trim_start();
    let body = if let Some(inside) = rest.strip_prefix('[') {
        &inside[..inside.find(']').unwrap_or(inside.len())]
    } else {
        rest.split([',', '\n', '}']).next().unwrap_or("")
    };
    body.split(',')
        .filter_map(|token| token.trim().parse::<f64>().ok())
        .collect()
}

/// The first number after `"key":`, NaN if there is none
pub fn number(text: &str, key: &str) -> f64 {
    numbers(text, key).first().copied().unwrap_or(f64::NAN)
}

// ---------------------------------------------------------------------------------------------------------------
// The arguments of each prediction
// ---------------------------------------------------------------------------------------------------------------

/// P5's call: 20 inline rows, the label in column 2, a test ratio of 0.3, the predictions returned
pub fn p5_arguments(labels: [f64; 2], seed: u64) -> Value {
    json!({
        "source": { "type": "inline", "data": pipeline::two_blobs(labels), "target_column": 2 },
        "split": { "test_ratio": 0.3, "seed": seed },
        "return_predictions": true,
    })
}

/// `pages` and `build_seconds` of `builds.csv`, the two numeric columns, written where the server can read them
pub fn write_numeric_builds(dir: &Path) -> std::io::Result<&'static str> {
    let b = crate::data::load_builds(crate::data_path("builds.csv"));
    let mut csv = String::from("pages,build_seconds\n");
    for (pages, seconds) in b.pages.column(0).iter().zip(&b.seconds) {
        csv.push_str(&format!("{pages},{seconds}\n"));
    }
    std::fs::write(dir.join("builds_numeric.csv"), csv)?;
    Ok("builds_numeric.csv")
}

/// P7 (b)'s rows: 10 of 3 features, the target a line in them plus a small wobble
pub fn three_feature_rows() -> Vec<Vec<f64>> {
    (0..10)
        .map(|i| {
            let i = i as f64;
            let (a, b, c) = (i, (i * 7.0) % 5.0, (i * 3.0) % 4.0);
            vec![a, b, c, 2.0 * a - b + 0.5 * c + 1.0 + 0.1 * (i % 3.0)]
        })
        .collect()
}

// ---------------------------------------------------------------------------------------------------------------
// The predictions, measured
// ---------------------------------------------------------------------------------------------------------------

/// P5 through the tool, for one pair of labels
#[derive(Debug)]
pub struct P5Tool {
    pub reply: Reply,
    pub model: String,
    pub accuracy: f64,
    /// Precision, recall, F1
    pub scores: [f64; 3],
    /// How many classes the returned predictions hold
    pub classes_in_test: usize,
}

pub fn p5_tool(server: &mut Server, labels: [f64; 2]) -> P5Tool {
    let reply = server.call(
        "ix_ml_pipeline",
        p5_arguments(labels, pipeline::SEED),
        ANSWER,
    );
    let t = reply.text();
    let mut predicted = numbers(t, "predictions");
    predicted.sort_by(f64::total_cmp);
    predicted.dedup();
    P5Tool {
        model: reply.json()["model"]
            .as_str()
            .unwrap_or_default()
            .to_string(),
        accuracy: number(t, "accuracy"),
        scores: [number(t, "precision"), number(t, "recall"), number(t, "f1")],
        classes_in_test: predicted.len(),
        reply,
    }
}

/// P6: lesson 1's three items to verify
pub struct P6 {
    /// (a) `builds.csv` as it is
    pub raw: Reply,
    /// (b) the numeric CSV, defaults
    pub defaults: Reply,
    pub defaults_replay: ClassifyReplay,
    /// (c) the numeric CSV, `regress`, `normalize`
    pub regress: Reply,
    /// The 13 predictions, then mse, rmse and R²
    pub regress_numbers: Vec<f64>,
    pub all_rows: RegressReplay,
    pub training_rows: RegressReplay,
}

impl P6 {
    /// The tool's accuracy, precision, recall and F1 on the defaults, as written
    pub fn defaults_numbers(&self) -> Vec<f64> {
        let t = self.defaults.text();
        ["accuracy", "precision", "recall", "f1"]
            .iter()
            .map(|k| number(t, k))
            .collect()
    }

    pub fn defaults_replay_numbers(&self) -> Vec<f64> {
        let r = &self.defaults_replay;
        vec![
            r.accuracy,
            r.macro_scores[0],
            r.macro_scores[1],
            r.macro_scores[2],
        ]
    }
}

pub fn p6(server: &mut Server) -> P6 {
    let raw_path = crate::data_path("builds.csv");
    let raw = server.call(
        "ix_ml_pipeline",
        json!({ "source": { "type": "csv", "path": raw_path, "target_column": "build_seconds" } }),
        ANSWER,
    );
    let numeric = write_numeric_builds(server.dir()).expect("the server's directory is writable");
    let defaults = server.call(
        "ix_ml_pipeline",
        json!({ "source": { "type": "csv", "path": numeric, "target_column": "build_seconds" } }),
        ANSWER,
    );
    let regress = server.call(
        "ix_ml_pipeline",
        json!({
            "source": { "type": "csv", "path": numeric, "target_column": "build_seconds" },
            "task": "regress",
            "preprocess": { "normalize": true },
            "return_predictions": true,
        }),
        ANSWER,
    );
    let t = regress.text();
    let mut regress_numbers = numbers(t, "predictions");
    regress_numbers.extend(["mse", "rmse", "r_squared"].map(|k| number(t, k)));
    let b = crate::data::load_builds(crate::data_path("builds.csv"));
    P6 {
        raw,
        defaults,
        defaults_replay: pipeline::replay_knn(
            &b.pages,
            &b.seconds,
            5,
            Scaling::None,
            pipeline::TEST_RATIO,
            pipeline::SEED,
        ),
        regress,
        regress_numbers,
        all_rows: pipeline::replay_regression(&b.pages, &b.seconds, Scaling::AllRows),
        training_rows: pipeline::replay_regression(&b.pages, &b.seconds, Scaling::TrainingRows),
    }
}

/// P7: one server, a persisted knn, then the panic
pub struct P7 {
    pub knn_persist: Reply,
    pub knn_predict: Reply,
    pub pca_persist: Reply,
    pub pca_predict: Reply,
    /// The stderr lines after the PCA prediction
    pub stderr_after_predict: String,
    pub tools_after: Option<usize>,
    pub valid_call_after: Reply,
    pub stderr_after_call: String,
}

pub fn p7(server: &mut Server) -> P7 {
    let mut knn = p5_arguments([1.0, 2.0], pipeline::SEED);
    knn["persist"] = json!(true);
    knn["persist_key"] = json!("l21-knn");
    let knn_persist = server.call("ix_ml_pipeline", knn, ANSWER);
    let row = [0.1, 0.1];
    let knn_predict = server.call(
        "ix_ml_predict",
        json!({ "persist_key": "l21-knn", "data": [row] }),
        ANSWER,
    );
    let pca_persist = server.call(
        "ix_ml_pipeline",
        json!({
            "source": { "type": "inline", "data": three_feature_rows(), "target_column": 3 },
            "task": "regress",
            "preprocess": { "normalize": true, "pca_components": 1 },
            "persist": true,
            "persist_key": "l21-pca",
        }),
        ANSWER,
    );
    let pca_predict = server.call(
        "ix_ml_predict",
        json!({ "persist_key": "l21-pca", "data": [[1.0, 2.0, 3.0]] }),
        SILENCE,
    );
    let stderr_after_predict = server.stderr();
    let tools_after = server.tools(ANSWER).map(|t| t.len());
    let valid_call_after = server.call(
        "ix_ml_pipeline",
        p5_arguments([1.0, 2.0], pipeline::SEED),
        SILENCE,
    );
    P7 {
        knn_persist,
        knn_predict,
        pca_persist,
        pca_predict,
        stderr_after_predict,
        tools_after,
        valid_call_after,
        stderr_after_call: server.stderr(),
    }
}

/// P8: a fresh server, the loop detector then the approval policy
pub struct P8 {
    /// P5's call with the seeds 1 to 11
    pub repeated: Vec<Reply>,
    pub predict_after: Reply,
    pub tools: Vec<String>,
    pub petri: Reply,
}

/// The six registered tools the approval policy lists nowhere, read in `ix-approval`'s `classify.rs`
pub const UNLISTED: [&str; 6] = [
    "ix_assumption_belief_at",
    "ix_assumption_claims",
    "ix_assumption_drift",
    "ix_assumption_query",
    "ix_mesh_correlate",
    "ix_petri_analyze",
];

pub fn p8(server: &mut Server) -> P8 {
    let repeated = (1..=11)
        .map(|seed| server.call("ix_ml_pipeline", p5_arguments([1.0, 2.0], seed), ANSWER))
        .collect();
    let predict_after = server.call(
        "ix_ml_predict",
        json!({ "persist_key": "l21-nothing-here", "data": [[0.0, 0.0]] }),
        ANSWER,
    );
    let tools = server.tools(ANSWER).unwrap_or_default();
    let petri = server.call(
        "ix_petri_analyze",
        json!({ "places": [], "transitions": [] }),
        ANSWER,
    );
    P8 {
        repeated,
        predict_after,
        tools,
        petri,
    }
}

/// The rows of a matrix and a vector, as the inline `data` of a call: the target last
pub fn inline_rows(x: &Array2<f64>, y: &Array1<f64>) -> Vec<Vec<f64>> {
    x.rows()
        .into_iter()
        .zip(y)
        .map(|(row, &target)| {
            let mut r = row.to_vec();
            r.push(target);
            r
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEXT: &str = r#"{
  "metrics": {
    "accuracy": 1.0,
    "f1": 0.6666666666666666,
    "precision": 0.6666666666666666
  },
  "predictions": [
    1,
    2.5e-3,
    -3.0
  ],
  "split": {
    "test": 6,
    "train": 14
  }
}"#;

    #[test]
    fn numbers_reads_a_value_or_an_array_as_written() {
        assert_eq!(number(TEXT, "accuracy"), 1.0);
        assert_eq!(
            number(TEXT, "precision").to_bits(),
            (2.0_f64 / 3.0).to_bits()
        );
        assert_eq!(numbers(TEXT, "predictions"), [1.0, 0.0025, -3.0]);
        assert_eq!(number(TEXT, "test"), 6.0);
        assert!(number(TEXT, "absent").is_nan());
    }

    #[test]
    fn the_three_feature_rows_have_a_target_per_row() {
        let rows = three_feature_rows();
        assert_eq!(rows.len(), 10);
        assert!(rows.iter().all(|r| r.len() == 4));
    }
}
