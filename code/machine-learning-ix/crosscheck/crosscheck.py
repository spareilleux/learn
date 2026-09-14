# Machine learning course: the results of the Rust examples that don't depend on IX's random numbers, recomputed with
# numpy and scikit-learn. Run from code/machine-learning-ix: python crosscheck/crosscheck.py
import csv
import warnings

import numpy as np
import sklearn
from sklearn.cluster import DBSCAN, KMeans
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.metrics import (accuracy_score, confusion_matrix, mean_absolute_error, mean_squared_error,
                             precision_recall_fscore_support, r2_score, silhouette_score)
from sklearn.mixture import GaussianMixture
from sklearn.neighbors import KNeighborsClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeClassifier, export_text

print(f"numpy {np.__version__}, scikit-learn {sklearn.__version__}")
OS = ["ubuntu", "windows", "macos"]


def read(name):
    with open(f"data/{name}", encoding="utf-8") as f:
        return list(csv.DictReader(f))


builds = read("builds.csv")
pages = np.array([[float(r["pages"])] for r in builds])
seconds = np.array([float(r["build_seconds"]) for r in builds])
jobs = read("jobs.csv")
features = ["queue_s", "setup_s", "checkout_s", "post_checkout_s", "complete_s"]
X = np.array([[float(r[f]) for f in features] for r in jobs])
os_ = np.array([OS.index(r["os"]) for r in jobs])

# Lesson 1: statistics, chronological split, baseline, scaler, always-ubuntu classifier
print("\n== lesson 1")
print(f"y mean {seconds.mean():.3f}, std {seconds.std():.3f}")
n_test = round(len(seconds) * 0.2)
train, test = slice(0, len(seconds) - n_test), slice(len(seconds) - n_test, None)
baseline = np.full(n_test, seconds[train].mean())
y_test = seconds[test]
print(f"baseline: mse {mean_squared_error(y_test, baseline):.3f}, rmse {np.sqrt(mean_squared_error(y_test, baseline)):.3f}, "
      f"mae {mean_absolute_error(y_test, baseline):.3f}, r2 {r2_score(y_test, baseline):.3f}")
scaler = StandardScaler().fit(pages[train])
print(f"StandardScaler on train rows: mean {scaler.mean_[0]:.3f}, std {scaler.scale_[0]:.3f}")
always = np.zeros(len(os_), dtype=int)
p, r, f, _ = precision_recall_fscore_support(os_, always, labels=[0, 1, 2], zero_division=0)
print(f"always ubuntu: accuracy {accuracy_score(os_, always):.3f}, f1 per class {np.round(f, 3).tolist()}, macro f1 {f.mean():.3f}")

# Lesson 2: least squares on the chronological training rows
print("\n== lesson 2")
line = LinearRegression().fit(pages[train], seconds[train])
predicted = line.predict(pages[test])
print(f"seconds = {line.coef_[0]:.6f} * pages + {line.intercept_:.6f}")
print(f"test: rmse {np.sqrt(mean_squared_error(y_test, predicted)):.3f}, mae {mean_absolute_error(y_test, predicted):.3f}, r2 {r2_score(y_test, predicted):.3f}")

# Lesson 3: every fifth job tests
print("\n== lesson 3")
is_test = np.arange(len(os_)) % 5 == 0
Xtr, Xte, ytr, yte = X[~is_test], X[is_test], os_[~is_test], os_[is_test]
two = [2, 3]
for C in [1.0, 1e6]:
    # scikit-learn minimizes the log loss plus a penalty on the weights; a large C makes the penalty negligible
    logistic = LogisticRegression(C=C, max_iter=10_000).fit(Xtr[:, two], ytr == 1)
    pred = logistic.predict(Xte[:, two])
    print(f"logistic C={C:g}: w {np.round(logistic.coef_[0], 4).tolist()} b {logistic.intercept_[0]:.4f}, test accuracy {accuracy_score(yte == 1, pred):.3f}")
scale = StandardScaler().fit(Xtr)
for label, a, b in [("raw", Xtr, Xte), ("standardized", scale.transform(Xtr), scale.transform(Xte))]:
    for k in [4, 5]:
        knn = KNeighborsClassifier(n_neighbors=k, algorithm="brute").fit(a, ytr)
        print(f"knn {label} k = {k}: test accuracy {accuracy_score(yte, knn.predict(b)):.3f}")
tree = DecisionTreeClassifier(max_depth=3, random_state=0).fit(Xtr, ytr)
print(export_text(tree, feature_names=features, class_names=OS).rstrip())
pred = tree.predict(Xte)
print(f"tree test accuracy {accuracy_score(yte, pred):.3f}")
print(confusion_matrix(yte, pred, labels=[0, 1, 2]))

# Lesson 4: the standardized jobs
print("\n== lesson 4")
Z = StandardScaler().fit_transform(X)
for k in range(2, 7):
    best = KMeans(n_clusters=k, n_init=50, random_state=0).fit(Z)
    print(f"k {k}: best inertia of 50 starts {best.inertia_:.3f}, silhouette {silhouette_score(Z, best.labels_):.4f}")
print(f"silhouette of [0, 1 | 10]: {silhouette_score(np.array([[0.0], [1.0], [10.0]]), [0, 0, 1]):.4f}")
with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")
    ghost = KMeans(n_clusters=3, n_init=1, random_state=0).fit(np.array([[5.0], [5.0], [9.0], [9.0]]))
print(f"KMeans(3) on [5, 5, 9, 9]: centroids {sorted(np.round(ghost.cluster_centers_[:, 0], 1).tolist())}, warning: {[str(w.message) for w in caught]}")
for eps in [0.5, 1.0, 1.5, 2.0]:
    labels = DBSCAN(eps=eps, min_samples=5).fit(Z).labels_
    sizes = [int((labels == c).sum()) for c in range(labels.max() + 1)]
    print(f"DBSCAN eps {eps}: cluster sizes {sizes}, noise {int((labels == -1).sum())}")
gmm = GaussianMixture(n_components=3, covariance_type="diag", n_init=10, random_state=0, reg_covar=1e-6).fit(Z)
print(f"GaussianMixture diag, best of 10 starts: log-likelihood {gmm.score(Z) * len(Z):.3f}, weights {sorted(np.round(gmm.weights_, 3).tolist(), reverse=True)}")
