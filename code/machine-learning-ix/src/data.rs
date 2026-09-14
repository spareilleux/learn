//! Loading the course data sets into ndarray matrices, the representation every IX algorithm takes.

use ndarray::{Array1, Array2};
use std::path::Path;

/// `data/builds.csv`: one row per build of this site, in commit order.
pub struct Builds {
    /// Pages of the site at the built commit, as a column: `n` rows, 1 feature
    pub pages: Array2<f64>,
    /// Seconds of the "Install, build, and upload site" step
    pub seconds: Array1<f64>,
    pub shas: Vec<String>,
}

/// `data/jobs.csv`: one row per CI job that checks out the repository.
pub struct Jobs {
    /// queue_s, setup_s, checkout_s, post_checkout_s, complete_s
    pub features: Array2<f64>,
    pub feature_names: Vec<String>,
    /// Runner OS as a class index into [`OS_NAMES`]
    pub os: Array1<usize>,
    pub workflows: Vec<String>,
}

pub const OS_NAMES: [&str; 3] = ["ubuntu", "windows", "macos"];

fn records(path: &Path) -> (csv::StringRecord, Vec<csv::StringRecord>) {
    let mut reader =
        csv::Reader::from_path(path).unwrap_or_else(|e| panic!("{}: {e}", path.display()));
    let header = reader.headers().unwrap().clone();
    let rows = reader.records().map(|r| r.unwrap()).collect();
    (header, rows)
}

pub fn load_builds(path: impl AsRef<Path>) -> Builds {
    let (_, rows) = records(path.as_ref());
    let n = rows.len();
    let pages = Array2::from_shape_fn((n, 1), |(i, _)| rows[i][2].parse().unwrap());
    let seconds = rows.iter().map(|r| r[3].parse().unwrap()).collect();
    let shas = rows.iter().map(|r| r[1].to_string()).collect();
    Builds {
        pages,
        seconds,
        shas,
    }
}

pub fn load_jobs(path: impl AsRef<Path>) -> Jobs {
    let (header, rows) = records(path.as_ref());
    // Columns 4 to 8 are the timings, column 3 the OS
    let feature_names = header.iter().skip(4).map(String::from).collect();
    let features = Array2::from_shape_fn((rows.len(), 5), |(i, j)| rows[i][4 + j].parse().unwrap());
    let os = rows
        .iter()
        .map(|r| {
            OS_NAMES
                .iter()
                .position(|&name| name == &r[3])
                .expect("unknown OS")
        })
        .collect();
    let workflows = rows.iter().map(|r| r[1].to_string()).collect();
    Jobs {
        features,
        feature_names,
        os,
        workflows,
    }
}
