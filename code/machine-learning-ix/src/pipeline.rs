//! Lesson 21: IX's `ix-pipeline`, its DAG, its executor and its lock file, then the steps behind the
//! `ix_ml_pipeline` MCP tool replayed with IX's own functions. Everything here runs anywhere; the tool itself
//! needs IX's MCP server, which only the `l21_mcp` program and the ignored tests start (see [`crate::mcp`]).

use ix_math::preprocessing::{InferredTask, StandardScaler, infer_task_type, train_test_split};
use ix_pipeline::builder::PipelineBuilder;
use ix_pipeline::dag::Dag;
use ix_pipeline::executor::{
    NoCache, PipelineCache, PipelineError, PipelineNode, PipelineResult, execute,
};
use ix_pipeline::lock::LockFile;
use ix_pipeline::lower::lower;
use ix_pipeline::spec::{PipelineSpec, StageSpec};
use ix_supervised::knn::KNN;
use ix_supervised::linear_regression::LinearRegression;
use ix_supervised::metrics::{self, Average};
use ix_supervised::traits::{Classifier, Regressor};
use ndarray::{Array1, Array2, Axis};
use serde_json::{Value, json};
use std::collections::{BTreeMap, HashMap};
use std::hash::{DefaultHasher, Hash, Hasher};
use std::sync::{Arc, Mutex};
use std::thread::{self, ThreadId};
use std::time::Duration;

/// The split `run_pipeline` uses when the caller sets none (ml_pipeline.rs 99-104)
pub const TEST_RATIO: f64 = 0.2;
pub const SEED: u64 = 42;

// ---------------------------------------------------------------------------------------------------------------
// P1 and P3: a diamond
// ---------------------------------------------------------------------------------------------------------------

/// P1's diamond after one run: `load` → `a` and `b` → `report`
pub struct Diamond {
    pub result: PipelineResult,
    /// `parallel_levels`, each level sorted by name: the executor's order inside a level follows a `HashMap`
    pub levels: Vec<Vec<String>>,
    /// The thread each compute function ran on, in the order they ran
    pub threads: Vec<(String, ThreadId)>,
    /// The thread that called `execute`
    pub caller: ThreadId,
}

type Seen = Arc<Mutex<Vec<(String, ThreadId)>>>;

fn note(seen: &Seen, name: &str) {
    seen.lock()
        .unwrap()
        .push((name.to_string(), thread::current().id()));
}

fn number(inputs: &HashMap<String, Value>, name: &str) -> f64 {
    inputs[name].as_f64().expect("a number")
}

/// Builds and runs the diamond; `a` and `b` each sleep `nap`, so a level that ran them side by side would take
/// one nap and a level that runs them in turn takes two.
pub fn diamond(nap: Duration) -> Diamond {
    let seen: Seen = Arc::default();
    let (s_load, s_a, s_b, s_report) = (seen.clone(), seen.clone(), seen.clone(), seen.clone());
    let dag = PipelineBuilder::new()
        .source("load", move || {
            note(&s_load, "load");
            Ok(json!(1.0))
        })
        .node("a", move |b| {
            b.input("x", "load").compute(move |i| {
                note(&s_a, "a");
                thread::sleep(nap);
                Ok(json!(number(i, "x") + 1.0))
            })
        })
        .node("b", move |b| {
            b.input("x", "load").compute(move |i| {
                note(&s_b, "b");
                thread::sleep(nap);
                Ok(json!(number(i, "x") + 2.0))
            })
        })
        .node("report", move |b| {
            b.input("a", "a").input("b", "b").compute(move |i| {
                note(&s_report, "report");
                Ok(json!(number(i, "a") + number(i, "b")))
            })
        })
        .build()
        .expect("a diamond has no cycle");
    let levels = dag
        .parallel_levels()
        .iter()
        .map(|level| {
            let mut names: Vec<String> = level.iter().map(|id| id.to_string()).collect();
            names.sort();
            names
        })
        .collect();
    let result = execute(&dag, &HashMap::new(), &NoCache).expect("the diamond runs");
    let threads = seen.lock().unwrap().clone();
    Diamond {
        result,
        levels,
        threads,
        caller: thread::current().id(),
    }
}

/// P3: what a node receives when it reads `field` of an upstream output `{"a": 1}` through `input_field`
pub fn read_field(field: &str) -> Value {
    let dag = PipelineBuilder::new()
        .source("up", || Ok(json!({ "a": 1 })))
        .node("down", |b| {
            b.input_field("v", "up", field)
                .compute(|i| Ok(i["v"].clone()))
        })
        .build()
        .expect("two nodes, one edge");
    let result = execute(&dag, &HashMap::new(), &NoCache).expect("it runs");
    result.output("down").expect("down ran").clone()
}

// ---------------------------------------------------------------------------------------------------------------
// P2: the cache key
// ---------------------------------------------------------------------------------------------------------------

/// An in-memory `PipelineCache`, like the one IX's own executor test writes (executor.rs 464-478)
#[derive(Default)]
pub struct MemoryCache(Mutex<HashMap<String, Value>>);

impl PipelineCache for MemoryCache {
    fn get(&self, key: &str) -> Option<Value> {
        self.0.lock().unwrap().get(key).cloned()
    }
    fn set(&self, key: &str, value: &Value) {
        self.0
            .lock()
            .unwrap()
            .insert(key.to_string(), value.clone());
    }
}

/// A pipeline of one node `f`, which reads the external input `value` and applies `f` to it
pub fn one_node(f: fn(f64) -> f64) -> Dag<PipelineNode> {
    PipelineBuilder::new()
        .node("f", move |b| {
            b.input("x", "value")
                .compute(move |i| Ok(json!(f(number(i, "x")))))
        })
        .build()
        .expect("one node")
}

/// P2: x + 1, then 2x, on `value` = 10, sharing one cache: (output, cache hits) for each run
pub fn shared_cache() -> [(f64, usize); 2] {
    let cache = MemoryCache::default();
    let inputs = HashMap::from([("value".to_string(), json!(10.0))]);
    [one_node(|x| x + 1.0), one_node(|x| 2.0 * x)].map(|dag| {
        let result = execute(&dag, &inputs, &cache).expect("it runs");
        (
            result.output("f").unwrap().as_f64().unwrap(),
            result.cache_hits,
        )
    })
}

// ---------------------------------------------------------------------------------------------------------------
// P4: the lock file's hash, and lowering without skills
// ---------------------------------------------------------------------------------------------------------------

/// `canonicalize` of lock.rs 329-346, rewritten: keys sorted, each written with `{:?}`, scalars as serde_json writes them
pub fn canonical(v: &Value) -> String {
    match v {
        Value::Object(map) => {
            let mut entries: Vec<(&String, &Value)> = map.iter().collect();
            entries.sort_by_key(|(k, _)| k.as_str());
            let parts: Vec<String> = entries
                .iter()
                .map(|(k, v)| format!("{k:?}:{}", canonical(v)))
                .collect();
            format!("{{{}}}", parts.join(","))
        }
        Value::Array(items) => {
            let parts: Vec<String> = items.iter().map(canonical).collect();
            format!("[{}]", parts.join(","))
        }
        other => serde_json::to_string(other).unwrap_or_default(),
    }
}

/// FNV-1a, 64 bits: the offset basis and prime the executor's `simple_hash` uses (executor.rs 318-325)
pub fn fnv1a64(bytes: &[u8]) -> u64 {
    bytes.iter().fold(0xcbf2_9ce4_8422_2325, |hash, &b| {
        (hash ^ b as u64).wrapping_mul(0x0000_0100_0000_01b3)
    })
}

/// What `hash_json` computes (lock.rs 320-327): the standard library's `DefaultHasher` over the string
pub fn default_hasher(s: &str) -> u64 {
    let mut hasher = DefaultHasher::new();
    s.hash(&mut hasher);
    hasher.finish()
}

pub struct LockHashes {
    /// `args_hash` as `LockFile::from_run` writes it
    pub args_hash: String,
    pub canonical: String,
    pub default_hasher: String,
    pub fnv1a64: String,
}

/// P4: `LockFile::from_run` on a stage `load` of skill `stats` with the args `{"data": [1.0, 2.0]}`
pub fn lock_hashes() -> LockHashes {
    let args = json!({ "data": [1.0, 2.0] });
    let stage = StageSpec {
        skill: "stats".into(),
        args: args.clone(),
        deps: vec![],
        cache: None,
    };
    let spec = PipelineSpec {
        version: "1".into(),
        params: BTreeMap::new(),
        stages: BTreeMap::from([("load".to_string(), stage)]),
        x_editor: Value::Null,
    };
    // A run with a node of the same id stands in for the skill, which the course doesn't link
    let dag = PipelineBuilder::new()
        .source("load", || Ok(json!({ "mean": 1.5 })))
        .build()
        .expect("one node");
    let result = execute(&dag, &HashMap::new(), &NoCache).expect("it runs");
    let lock = LockFile::from_run(&spec, &result, &HashMap::new());
    let canonical = canonical(&args);
    LockHashes {
        args_hash: lock.stages["load"].args_hash.clone(),
        default_hasher: format!("fnv1a64:{:016x}", default_hasher(&canonical)),
        fnv1a64: format!("fnv1a64:{:016x}", fnv1a64(canonical.as_bytes())),
        canonical,
    }
}

/// P4: `lower` on the scaffold `ix pipeline new` writes, in a program that links no `#[ix_skill]`
pub fn lower_scaffold() -> String {
    match lower(&PipelineSpec::scaffold("demo")) {
        Ok(dag) => format!("lowered, {} nodes", dag.node_count()),
        Err(e) => e.to_string(),
    }
}

// ---------------------------------------------------------------------------------------------------------------
// P5: macro averages
// ---------------------------------------------------------------------------------------------------------------

/// The macro average `run_classification` computes (ml_pipeline.rs 655-670): precision, recall and F1 of every
/// class from 0 to `n_classes - 1`, divided by `n_classes`
pub fn tool_macro(y_true: &Array1<usize>, y_pred: &Array1<usize>, n_classes: usize) -> [f64; 3] {
    let mut sums = [0.0; 3];
    for c in 0..n_classes {
        sums[0] += metrics::precision(y_true, y_pred, c);
        sums[1] += metrics::recall(y_true, y_pred, c);
        sums[2] += metrics::f1_score(y_true, y_pred, c);
    }
    sums.map(|s| s / n_classes as f64)
}

/// IX's own macro averages, `precision_avg`, `recall_avg` and `f1_avg` (metrics.rs 169-211)
pub fn ix_macro(y_true: &Array1<usize>, y_pred: &Array1<usize>) -> [f64; 3] {
    [
        metrics::precision_avg(y_true, y_pred, Average::Macro),
        metrics::recall_avg(y_true, y_pred, Average::Macro),
        metrics::f1_avg(y_true, y_pred, Average::Macro),
    ]
}

/// P5's rows: ten of class `labels[0]` on a grid near (0, 0), ten of class `labels[1]` on the same grid near (5, 5);
/// the label is the third column
pub fn two_blobs(labels: [f64; 2]) -> Vec<Vec<f64>> {
    (0..20)
        .map(|i| {
            let (shift, label) = if i < 10 {
                (0.0, labels[0])
            } else {
                (5.0, labels[1])
            };
            let j = i % 10;
            vec![
                shift + (j % 5) as f64 / 10.0,
                shift + (j / 5) as f64 / 10.0,
                label,
            ]
        })
        .collect()
}

// ---------------------------------------------------------------------------------------------------------------
// The steps of `run_pipeline`, replayed with IX's functions
// ---------------------------------------------------------------------------------------------------------------

/// Where the standard scaler learns its means and deviations
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Scaling {
    None,
    /// On every row, before the split: what `run_pipeline` does with `normalize` on (ml_pipeline.rs 190-195)
    AllRows,
    /// On the training rows, after the split: what ML.NET's and scikit-learn's pipelines do
    TrainingRows,
}

/// The split, then the scaler where `scaling` says: (x_train, x_test, y_train, y_test)
fn split_and_scale(
    x: &Array2<f64>,
    y: &Array1<f64>,
    scaling: Scaling,
    test_ratio: f64,
    seed: u64,
) -> (Array2<f64>, Array2<f64>, Array1<f64>, Array1<f64>) {
    let x = if scaling == Scaling::AllRows {
        StandardScaler::fit_transform(x).expect("rows").1
    } else {
        x.clone()
    };
    let s = train_test_split(&x, y, test_ratio, seed).expect("a valid split");
    if scaling == Scaling::TrainingRows {
        let scaler = StandardScaler::fit(&s.x_train).expect("rows");
        (
            scaler.transform(&s.x_train),
            scaler.transform(&s.x_test),
            s.y_train,
            s.y_test,
        )
    } else {
        (s.x_train, s.x_test, s.y_train, s.y_test)
    }
}

/// What `run_pipeline` would decide with task and model on `auto` (ml_pipeline.rs 208-228, 507-522)
pub fn auto_choice(x: &Array2<f64>, y: &Array1<f64>) -> (&'static str, &'static str) {
    let task = match infer_task_type(y.as_slice().expect("contiguous"), 20) {
        InferredTask::Regression => "regress",
        InferredTask::BinaryClassification | InferredTask::MulticlassClassification { .. } => {
            "classify"
        }
    };
    let model = match task {
        "classify" if x.nrows() < 100 => "knn",
        "classify" if x.nrows() <= 10_000 && x.ncols() < 20 => "decision_tree",
        "classify" => "random_forest",
        _ => "linear_regression",
    };
    (task, model)
}

/// A classification as `run_classification` runs it with `knn` (ml_pipeline.rs 524-556, 655-670)
#[derive(Debug, PartialEq)]
pub struct ClassifyReplay {
    pub train: usize,
    pub test: usize,
    pub n_classes: usize,
    pub accuracy: f64,
    /// Precision, recall, F1, averaged over `0..n_classes`
    pub macro_scores: [f64; 3],
    pub predictions: Vec<usize>,
}

pub fn replay_knn(
    x: &Array2<f64>,
    y: &Array1<f64>,
    k: usize,
    scaling: Scaling,
    test_ratio: f64,
    seed: u64,
) -> ClassifyReplay {
    let as_class = |v: &f64| v.round() as usize;
    let n_classes = y.iter().map(as_class).max().unwrap_or(0) + 1;
    let (x_train, x_test, y_train, y_test) = split_and_scale(x, y, scaling, test_ratio, seed);
    let (y_train, y_test) = (y_train.map(as_class), y_test.map(as_class));
    let mut model = KNN::new(k);
    model.fit(&x_train, &y_train);
    let predictions = model.predict(&x_test);
    ClassifyReplay {
        train: x_train.nrows(),
        test: x_test.nrows(),
        n_classes,
        accuracy: metrics::accuracy(&y_test, &predictions),
        macro_scores: tool_macro(&y_test, &predictions, n_classes),
        predictions: predictions.to_vec(),
    }
}

/// A regression as `run_regression` runs it with `linear_regression` (ml_pipeline.rs 697-765)
#[derive(Debug, PartialEq)]
pub struct RegressReplay {
    pub predictions: Vec<f64>,
    pub mse: f64,
    pub rmse: f64,
    pub r_squared: f64,
}

impl RegressReplay {
    /// The 13 predictions and the three metrics, the 16 numbers P6 compares bit for bit
    pub fn numbers(&self) -> Vec<f64> {
        let mut all = self.predictions.clone();
        all.extend([self.mse, self.rmse, self.r_squared]);
        all
    }
}

fn score(y_test: &Array1<f64>, predictions: Array1<f64>) -> RegressReplay {
    RegressReplay {
        mse: metrics::mse(y_test, &predictions),
        rmse: metrics::rmse(y_test, &predictions),
        r_squared: metrics::r_squared(y_test, &predictions),
        predictions: predictions.to_vec(),
    }
}

pub fn replay_regression(x: &Array2<f64>, y: &Array1<f64>, scaling: Scaling) -> RegressReplay {
    let (x_train, x_test, y_train, y_test) = split_and_scale(x, y, scaling, TEST_RATIO, SEED);
    let mut model = LinearRegression::new();
    model.fit(&x_train, &y_train);
    score(&y_test, model.predict(&x_test))
}

/// How many of two lists of numbers are the same to the last bit
pub fn same_bits(a: &[f64], b: &[f64]) -> usize {
    a.iter()
        .zip(b)
        .filter(|(p, q)| p.to_bits() == q.to_bits())
        .count()
}

// ---------------------------------------------------------------------------------------------------------------
// The order MLContext follows, as an ix-pipeline DAG
// ---------------------------------------------------------------------------------------------------------------

fn matrix_json(x: &Array2<f64>) -> Value {
    json!(
        x.axis_iter(Axis(0))
            .map(|row| row.to_vec())
            .collect::<Vec<_>>()
    )
}

fn json_matrix(v: &Value) -> Array2<f64> {
    let rows: Vec<Vec<f64>> = serde_json::from_value(v.clone()).expect("a matrix");
    let cols = rows.first().map_or(0, Vec::len);
    Array2::from_shape_vec((rows.len(), cols), rows.concat()).expect("rows of one length")
}

fn json_vector(v: &Value) -> Array1<f64> {
    Array1::from_vec(serde_json::from_value(v.clone()).expect("a vector"))
}

fn fail(e: impl std::fmt::Display) -> PipelineError {
    PipelineError::ComputeError(e.to_string())
}

/// Split, fit the scaler on the training rows, scale both sides, fit and predict, score: each step a node, the data
/// between them JSON. Returns the DAG's levels and its scores.
pub fn leak_free_dag(x: &Array2<f64>, y: &Array1<f64>) -> (Vec<Vec<String>>, RegressReplay) {
    let data = json!({ "x": matrix_json(x), "y": y.to_vec() });
    let dag = PipelineBuilder::new()
        .source("data", move || Ok(data.clone()))
        .node("split", |b| {
            b.input("d", "data").compute(|i| {
                let s = train_test_split(
                    &json_matrix(&i["d"]["x"]),
                    &json_vector(&i["d"]["y"]),
                    TEST_RATIO,
                    SEED,
                )
                .map_err(fail)?;
                Ok(json!({
                    "x_train": matrix_json(&s.x_train), "x_test": matrix_json(&s.x_test),
                    "y_train": s.y_train.to_vec(), "y_test": s.y_test.to_vec(),
                }))
            })
        })
        .node("scaler", |b| {
            b.input_field("x", "split", "x_train").compute(|i| {
                let scaler = StandardScaler::fit(&json_matrix(&i["x"])).map_err(fail)?;
                Ok(json!({ "means": scaler.means.to_vec(), "stds": scaler.stds.to_vec() }))
            })
        })
        .node("scale", |b| {
            b.input("s", "split").input("c", "scaler").compute(|i| {
                let scaler = StandardScaler {
                    means: json_vector(&i["c"]["means"]),
                    stds: json_vector(&i["c"]["stds"]),
                };
                Ok(json!({
                    "x_train": matrix_json(&scaler.transform(&json_matrix(&i["s"]["x_train"]))),
                    "x_test": matrix_json(&scaler.transform(&json_matrix(&i["s"]["x_test"]))),
                }))
            })
        })
        .node("fit_predict", |b| {
            b.input("x", "scale")
                .input_field("y", "split", "y_train")
                .compute(|i| {
                    let mut model = LinearRegression::new();
                    model.fit(&json_matrix(&i["x"]["x_train"]), &json_vector(&i["y"]));
                    Ok(json!(
                        model.predict(&json_matrix(&i["x"]["x_test"])).to_vec()
                    ))
                })
        })
        .node("score", |b| {
            b.input("p", "fit_predict")
                .input_field("y", "split", "y_test")
                .compute(|i| {
                    let r = score(&json_vector(&i["y"]), json_vector(&i["p"]));
                    Ok(json!({ "predictions": r.predictions, "mse": r.mse, "rmse": r.rmse, "r_squared": r.r_squared }))
                })
        })
        .build()
        .expect("a chain has no cycle");
    let levels = dag
        .parallel_levels()
        .iter()
        .map(|level| level.iter().map(|id| id.to_string()).collect())
        .collect();
    let result = execute(&dag, &HashMap::new(), &NoCache).expect("the pipeline runs");
    let out = result.output("score").expect("score ran");
    let replay = RegressReplay {
        predictions: serde_json::from_value(out["predictions"].clone()).unwrap(),
        mse: out["mse"].as_f64().unwrap(),
        rmse: out["rmse"].as_f64().unwrap(),
        r_squared: out["r_squared"].as_f64().unwrap(),
    };
    (levels, replay)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::data::load_builds;
    use ndarray::array;

    #[test]
    fn p1_a_level_of_two_runs_its_nodes_in_turn_on_the_callers_thread() {
        let d = diamond(Duration::from_millis(50));
        assert_eq!(d.levels, [vec!["load"], vec!["a", "b"], vec!["report"]]);
        assert_eq!(d.threads.len(), 4);
        assert!(d.threads.iter().all(|(_, t)| *t == d.caller));
        assert!(d.result.total_duration >= Duration::from_millis(100));
        assert_eq!(d.result.output("report").unwrap().as_f64(), Some(5.0));
    }

    #[test]
    fn p2_the_cache_key_leaves_out_what_a_node_computes() {
        assert_eq!(shared_cache(), [(11.0, 0), (11.0, 1)]);
    }

    #[test]
    fn p3_final_outputs_are_every_output_and_a_missing_field_passes_the_whole_output() {
        let d = diamond(Duration::ZERO);
        assert_eq!(d.result.final_outputs().len(), 4);
        assert_eq!(read_field("missing"), json!({ "a": 1 }));
        assert_eq!(read_field("a"), json!(1));
    }

    #[test]
    fn p4_the_lock_hash_is_default_hasher_under_the_name_fnv1a64_and_lower_finds_no_skill() {
        let h = lock_hashes();
        assert_eq!(h.canonical, r#"{"data":[1.0,2.0]}"#);
        assert_eq!(h.args_hash, h.default_hasher);
        assert_ne!(h.args_hash, h.fnv1a64);
        assert_eq!(h.args_hash.len(), "fnv1a64:".len() + 16);
        assert_eq!(
            lower_scaffold(),
            "stage 'load' references unknown skill 'stats'"
        );
    }

    #[test]
    fn p5_the_macro_average_counts_the_absent_class_0() {
        let y = array![1usize, 2, 1, 2, 2];
        let n_classes = 3;
        assert_eq!(tool_macro(&y, &y, n_classes), [2.0 / 3.0; 3]);
        assert_eq!(ix_macro(&y, &y), [2.0 / 3.0; 3]);
        assert_eq!(format!("{}", 2.0_f64 / 3.0), "0.6666666666666666");
        // with the classes 0 and 1 nothing is absent
        let y = array![0usize, 1, 0, 1];
        assert_eq!(tool_macro(&y, &y, 2), [1.0; 3]);
    }

    #[test]
    fn fnv1a64_matches_the_published_test_vectors() {
        // http://www.isthe.com/chongo/src/fnv/test_fnv.c: "" and "a"
        assert_eq!(fnv1a64(b""), 0xcbf29ce484222325);
        assert_eq!(fnv1a64(b"a"), 0xaf63dc4c8601ec8c);
    }

    #[test]
    fn the_leak_free_dag_gives_the_training_rows_replay() {
        let b = load_builds(crate::data_path("builds.csv"));
        let (levels, dag) = leak_free_dag(&b.pages, &b.seconds);
        assert_eq!(levels.len(), 6);
        let replay = replay_regression(&b.pages, &b.seconds, Scaling::TrainingRows);
        assert_eq!(same_bits(&dag.numbers(), &replay.numbers()), 16);
    }

    #[test]
    fn two_blobs_are_twenty_rows_of_two_classes() {
        let rows = two_blobs([1.0, 2.0]);
        assert_eq!(rows.len(), 20);
        assert_eq!(rows[13], vec![5.3, 5.0, 2.0]);
    }
}
