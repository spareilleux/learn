//! Lesson 5: a first classifier. Iris, 4 → 16 → 3 with a ReLU, trained with AdamW in f64, then the same
//! training in f32 and with plain SGD, every run starting from the same seeded weights.

use candle_core::{DType, Device, Tensor};
use candle_course::{iris, reseed};
use candle_nn::{AdamW, Optimizer, ParamsAdamW, SGD, VarBuilder, VarMap};

const EPOCHS: usize = 300;
const SEED: u64 = 5;
const REPORT: [usize; 6] = [1, 10, 50, 100, 200, 300];

/// A fresh model of the given type, with the seeded weights
fn seeded_model(
    dtype: DType,
    dev: &Device,
) -> candle_core::Result<(VarMap, candle_nn::Sequential)> {
    let varmap = VarMap::new();
    let model = iris::model(VarBuilder::from_varmap(&varmap, dtype, dev))?;
    reseed(&varmap, SEED)?;
    Ok((varmap, model))
}

fn print_losses(label: &str, losses: &[f64]) {
    let shown: Vec<String> = REPORT
        .iter()
        .map(|&e| format!("{e}: {:.4}", losses[e - 1]))
        .collect();
    println!("{label}, loss at epoch {}", shown.join(", "));
}

fn main() -> anyhow::Result<()> {
    let dev = Device::Cpu;
    let rows = iris::parse(include_str!("../../data/bezdekIris.data"));
    let data = iris::split(&rows);
    println!("== data: bezdekIris.data");
    println!(
        "{} rows; training {}, test {}; per species in the test set: {:?}",
        rows.len(),
        data.train_y.len(),
        data.test_y.len(),
        (0..3)
            .map(|s| data.test_y.iter().filter(|&&y| y == s).count())
            .collect::<Vec<_>>()
    );
    println!("training means (cm): {:.4?}", data.means);
    println!("training sds (cm):   {:.4?}", data.sds);

    let y_train = Tensor::new(data.train_y.as_slice(), &dev)?;
    let x_train = iris::features(&data.train_x, DType::F64, &dev)?;
    let x_test = iris::features(&data.test_x, DType::F64, &dev)?;

    println!("\n== AdamW, learning rate 0.01, {EPOCHS} full-batch epochs, F64");
    let (varmap, model) = seeded_model(DType::F64, &dev)?;
    let params = ParamsAdamW {
        lr: 0.01,
        ..Default::default()
    };
    let mut adamw = AdamW::new(varmap.all_vars(), params.clone())?;
    let losses = iris::train(&model, &mut adamw, &x_train, &y_train, EPOCHS)?;
    print_losses("F64", &losses);
    let final_f64 = iris::loss(&model, &x_train, &y_train)?;
    let train_pred = iris::predict(&model, &x_train)?;
    let test_pred = iris::predict(&model, &x_test)?;
    let correct =
        |pred: &[u32], truth: &[u32]| pred.iter().zip(truth).filter(|(a, b)| a == b).count();
    println!(
        "after training: loss {final_f64:.4}, training {}/{}, test {}/{}",
        correct(&train_pred, &data.train_y),
        data.train_y.len(),
        correct(&test_pred, &data.test_y),
        data.test_y.len()
    );
    println!("test confusion matrix (rows: species, columns: prediction)");
    for (s, name) in iris::SPECIES.iter().enumerate() {
        let counts: Vec<usize> = (0..3)
            .map(|p| {
                test_pred
                    .iter()
                    .zip(&data.test_y)
                    .filter(|&(&a, &b)| b == s as u32 && a == p)
                    .count()
            })
            .collect();
        println!("  {name:<10} {counts:?}");
    }
    for (i, (p, y)) in test_pred.iter().zip(&data.test_y).enumerate() {
        if p != y {
            let x: Vec<f64> = (0..4)
                .map(|j| data.test_x[i][j] * data.sds[j] + data.means[j])
                .collect();
            println!(
                "  test row {i}: {:?} cm, a {} taken for a {}",
                x.iter().map(|v| format!("{v:.1}")).collect::<Vec<_>>(),
                iris::SPECIES[*y as usize],
                iris::SPECIES[*p as usize]
            );
        }
    }

    println!("\n== the same training in F32, from the same weights");
    let (varmap32, model32) = seeded_model(DType::F32, &dev)?;
    let mut adamw32 = AdamW::new(varmap32.all_vars(), params)?;
    let x_train32 = x_train.to_dtype(DType::F32)?;
    let losses32 = iris::train(&model32, &mut adamw32, &x_train32, &y_train, EPOCHS)?;
    print_losses("F32", &losses32);
    let final_f32 = iris::loss(&model32, &x_train32, &y_train)?;
    let test_pred32 = iris::predict(&model32, &x_test.to_dtype(DType::F32)?)?;
    println!(
        "final loss within 1e-4 of F64 {}, same 30 test predictions {}",
        (final_f32 - final_f64).abs() < 1e-4,
        test_pred32 == test_pred
    );

    println!("\n== plain SGD, learning rate 0.1, from the same weights, F64");
    let (varmap_sgd, model_sgd) = seeded_model(DType::F64, &dev)?;
    let mut sgd = SGD::new(varmap_sgd.all_vars(), 0.1)?;
    let losses_sgd = iris::train(&model_sgd, &mut sgd, &x_train, &y_train, EPOCHS)?;
    print_losses("SGD", &losses_sgd);
    let final_sgd = iris::loss(&model_sgd, &x_train, &y_train)?;
    let test_sgd = iris::predict(&model_sgd, &x_test)?;
    println!(
        "after training: loss {final_sgd:.4}, test {}/{}, higher than AdamW's: {}",
        correct(&test_sgd, &data.test_y),
        data.test_y.len(),
        final_sgd > final_f64
    );
    Ok(())
}
