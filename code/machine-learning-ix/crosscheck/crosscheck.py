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

# Lesson 5: principal components. scikit-learn signs each component so that its largest entry is
# positive, the same rule the course's Jacobi version applies.
print("\n== lesson 5")
from sklearn.decomposition import PCA  # noqa: E402

Z5 = StandardScaler().fit_transform(X)
pca5 = PCA(n_components=5).fit(Z5)
print(f"explained variance {np.round(pca5.explained_variance_, 4).tolist()}")
print(f"ratios             {np.round(pca5.explained_variance_ratio_, 4).tolist()}")
print(f"sum of ratios      {pca5.explained_variance_ratio_.sum():.4f}")
for i in range(5):
    print(f"component {i + 1}: {np.round(pca5.components_[i], 3).tolist()}")
pca2 = PCA(n_components=2).fit(Z5)
print(f"two components: ratios {np.round(pca2.explained_variance_ratio_, 4).tolist()}, "
      f"sum {pca2.explained_variance_ratio_.sum():.4f}")
scores2 = pca2.transform(Z5)
print(f"first three jobs: {[np.round(scores2[i], 4).tolist() for i in range(3)]}")
for k in range(1, 6):
    p = PCA(n_components=k).fit(Z5)
    back = p.inverse_transform(p.transform(Z5))
    print(f"k {k}: reconstruction error {((Z5 - back) ** 2).mean():.4f}, "
          f"variance kept {p.explained_variance_ratio_.sum():.4f}")
anti = np.array([[1.0, -1.0], [-1.0, 1.0], [2.0, -2.0], [-2.0, 2.0], [1.0, 1.0], [-1.0, -1.0]])
anti_pca = PCA(n_components=2).fit(anti)
print(f"the cloud stretched along (1, -1): variance {np.round(anti_pca.explained_variance_, 4).tolist()}, "
      f"first component {np.round(anti_pca.components_[0], 4).tolist()}")

# Lesson 6: the course's own generator replayed, then the same boosting recipe in numpy.
print("\n== lesson 6")


def xorshift(seed):
    x = seed if seed else 1
    mask = (1 << 64) - 1
    while True:
        x ^= (x << 13) & mask
        x ^= x >> 7
        x ^= (x << 17) & mask
        yield x


def bootstrap(n, rng):
    return [next(rng) % n for _ in range(n)]


rng = xorshift(42)
sample = bootstrap(148, rng)
left_out = sorted(set(range(148)) - set(sample))
print(f"bootstrap of 148 rows, seed 42: {148 - len(left_out)} distinct rows, {len(left_out)} left out "
      f"({len(left_out) / 148:.3f}); 1/e = {1 / np.e:.3f}")

test_idx = [i for i in range(len(os_)) if i % 5 == 0]
train_idx = [i for i in range(len(os_)) if i % 5 != 0]
Xtr6, Xte6 = X[train_idx], X[test_idx]
ytr6, yte6 = os_[train_idx], os_[test_idx]


def stump_fit(x, residuals):
    n, p = x.shape
    total = residuals.sum()
    best = (-np.inf, 0, 0.0, total / n, total / n)
    for feature in range(p):
        order = np.argsort(x[:, feature], kind="stable")
        left_sum = 0.0
        for cut in range(n - 1):
            left_sum += residuals[order[cut]]
            lo, hi = x[order[cut], feature], x[order[cut + 1], feature]
            if abs(lo - hi) < 1e-12:
                continue
            ln, rn = cut + 1, n - cut - 1
            lm, rm = left_sum / ln, (total - left_sum) / rn
            score = ln * lm * lm + rn * rm * rm
            if score > best[0]:
                best = (score, feature, (lo + hi) / 2.0, lm, rm)
    return best[1:]


def softmax(scores):
    e = np.exp(scores - scores.max(axis=1, keepdims=True))
    return e / e.sum(axis=1, keepdims=True)


def boost(x, y, classes, rounds, rate):
    n = len(y)
    counts = np.bincount(y, minlength=classes)
    init = np.log((counts + 1.0) / (n + classes))
    scores = np.tile(init, (n, 1))
    trees = []
    for _ in range(rounds):
        proba = softmax(scores)
        round_trees = []
        for c in range(classes):
            residuals = (y == c).astype(float) - proba[:, c]
            feature, threshold, left, right = stump_fit(x, residuals)
            scores[:, c] += rate * np.where(x[:, feature] <= threshold, left, right)
            round_trees.append((feature, threshold, left, right))
        trees.append(round_trees)
    return init, trees


def boost_predict(init, trees, x, rate):
    scores = np.tile(init, (len(x), 1))
    for round_trees in trees:
        for c, (feature, threshold, left, right) in enumerate(round_trees):
            scores[:, c] += rate * np.where(x[:, feature] <= threshold, left, right)
    return scores.argmax(axis=1)


for rounds in [1, 5, 10, 25, 50]:
    init, trees = boost(Xtr6, ytr6, 3, rounds, 0.3)
    pred = boost_predict(init, trees, Xte6, 0.3)
    print(f"{rounds:2} rounds of boosting on stumps: test accuracy {accuracy_score(yte6, pred):.4f}")
init, trees = boost(Xtr6, ytr6, 3, 1, 0.3)
print(f"smoothed log priors {np.round(init, 4).tolist()}")
for c in range(3):
    feature, threshold, left, right = trees[0][c]
    print(f"round 1, class {OS[c]:<7}: split {features[feature]} <= {threshold:.1f}, "
          f"leaves {left:.4f} and {right:.4f}")

# Lesson 7: the gradient ix_nn::layer::Dense applies, measured in numpy.
print("\n== lesson 7")
xs = (pages[:, 0] - pages[:, 0].mean()) / pages[:, 0].std()
ts = (seconds - seconds.mean()) / seconds.std()
n7 = len(xs)


def mse_loss(w, columns=1):
    prediction = np.outer(xs, np.full(columns, w if np.isscalar(w) else w))
    target = np.column_stack([ts * (j + 1) for j in range(columns)])
    return ((prediction - target) ** 2).mean()


h = 1e-6
measured = (mse_loss(0.4 + h) - mse_loss(0.4 - h)) / (2 * h)
print(f"gradient of the mean squared error at w = 0.4: {measured:.9f}")
print(f"what Dense subtracts is that divided by the {n7} rows: {measured / n7:.9f}")
print(f"the exclusive-or targets have variance {np.var([0.0, 1.0, 1.0, 0.0]):.4f}, "
      "the loss a constant cannot beat")

# Lesson 8: the three update rules in numpy, on the same function from the same start.
print("\n== lesson 8")


def rosen(v):
    return (1 - v[0]) ** 2 + 100 * (v[1] - v[0] ** 2) ** 2


def rosen_grad(v):
    return np.array([-2 * (1 - v[0]) - 400 * v[0] * (v[1] - v[0] ** 2), 200 * (v[1] - v[0] ** 2)])


def run(rule, start, steps=5000, tol=1e-8):
    p = np.array(start, dtype=float)
    for i in range(steps):
        g = rosen_grad(p)
        if np.sqrt(g @ g) < tol:
            return p, i + 1
        p = rule(p, g)
    return p, steps


def sgd(rate):
    return lambda p, g: p - rate * g


def momentum(rate, beta):
    state = {"v": None}

    def step(p, g):
        state["v"] = rate * g if state["v"] is None else beta * state["v"] + rate * g
        return p - state["v"]

    return step


def adam(rate, b1=0.9, b2=0.999, eps=1e-8):
    state = {"m": None, "v": None, "t": 0}

    def step(p, g):
        state["t"] += 1
        state["m"] = (1 - b1) * g if state["m"] is None else b1 * state["m"] + (1 - b1) * g
        state["v"] = (1 - b2) * g * g if state["v"] is None else b2 * state["v"] + (1 - b2) * g * g
        mh = state["m"] / (1 - b1 ** state["t"])
        vh = state["v"] / (1 - b2 ** state["t"])
        return p - rate * mh / (np.sqrt(vh) + eps)

    return step


for name, rule in [("SGD", sgd(0.001)), ("Momentum", momentum(0.001, 0.9)), ("Adam", adam(0.05))]:
    point, steps = run(rule, [-1.2, 1.0])
    print(f"{name:9} {steps:5} steps: last {np.round(point, 4).tolist()} f {rosen(point):.6f}")
slope = float((xs * ts).mean())
print(f"the build-time line, standardized: closed-form slope {slope:.6f}")
