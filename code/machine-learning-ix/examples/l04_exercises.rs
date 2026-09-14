//! Lesson 4, exercise solutions.

use ix_unsupervised::dbscan::DBSCAN;
use ix_unsupervised::kmeans::KMeans;
use ix_unsupervised::traits::Clusterer;
use machine_learning_ix::data::{OS_NAMES, load_jobs};
use machine_learning_ix::evaluation::Scaler;
use machine_learning_ix::{cluster, data_path};
use ndarray::Array2;
use std::collections::BTreeMap;

fn main() {
    let jobs = load_jobs(data_path("jobs.csv"));
    let z = Scaler::fit(&jobs.features).transform(&jobs.features);

    // Exercise 1: k-means with k = 3 on the raw seconds, against the standardized features of the lesson
    println!("== exercise 1");
    for (name, x) in [("raw", &jobs.features), ("standardized", &z)] {
        let labels = KMeans::new(3).with_seed(42).fit_predict(x);
        let mut table = Array2::<usize>::zeros((3, 3));
        for (&l, &o) in labels.iter().zip(&jobs.os) {
            table[[l, o]] += 1;
        }
        println!(
            "{name}: silhouette {:.4}, clusters (rows) against {OS_NAMES:?}:\n{table}",
            cluster::silhouette(x, &labels.to_vec())
        );
    }

    // Exercise 2: the jobs DBSCAN calls noise, eps 1.0, min_points 5, counted by workflow and OS
    let labels = DBSCAN::new(1.0, 5).fit_predict(&z);
    let mut noise: BTreeMap<(String, &str), usize> = BTreeMap::new();
    for (i, &l) in labels.iter().enumerate() {
        if l == 0 {
            *noise
                .entry((jobs.workflows[i].clone(), OS_NAMES[jobs.os[i]]))
                .or_default() += 1;
        }
    }
    println!("\n== exercise 2");
    for ((workflow, os), n) in &noise {
        println!("{n:2} {workflow} ({os})");
    }
    let features = &jobs.features;
    let queue_noise: Vec<f64> = (0..labels.len())
        .filter(|&i| labels[i] == 0)
        .map(|i| features[[i, 0]])
        .collect();
    let queue_rest: Vec<f64> = (0..labels.len())
        .filter(|&i| labels[i] != 0)
        .map(|i| features[[i, 0]])
        .collect();
    println!(
        "mean queue_s: noise {:.2}, clustered {:.2}",
        queue_noise.iter().sum::<f64>() / queue_noise.len() as f64,
        queue_rest.iter().sum::<f64>() / queue_rest.len() as f64
    );
}
