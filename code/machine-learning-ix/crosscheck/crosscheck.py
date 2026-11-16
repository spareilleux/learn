# Machine learning course: the results of the Rust examples that don't depend on IX's random numbers, recomputed with
# numpy and scikit-learn. Run from code/machine-learning-ix: python crosscheck/crosscheck.py
import csv
import math
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

# Lesson 9: compare invariant properties, not coordinates (eigenvector signs and rotations
# are arbitrary, and t-SNE and NMF use different seeded initializers in Rust and Python).
print("\n== lesson 9")
from sklearn.decomposition import KernelPCA, NMF  # noqa: E402
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis  # noqa: E402
from sklearn.manifold import TSNE  # noqa: E402

square = np.array([[0., 0.], [1., 0.], [1., 1.], [0., 1.]])
d = np.linalg.norm(square[:, None] - square[None, :], axis=2)
d2 = d * d
gram = -.5 * (d2 - d2.mean(axis=0) - d2.mean(axis=1)[:, None] + d2.mean())
values, vectors = np.linalg.eigh(gram)
embedded = vectors[:, -2:] * np.sqrt(np.maximum(values[-2:], 0))
recovered = np.linalg.norm(embedded[:, None] - embedded[None, :], axis=2)
print(f"classical MDS recovers square distances: {bool(np.max(np.abs(d - recovered)) < 1e-10)}")

rings = np.array([[1., 0.], [-1., 0.], [0., 1.], [0., -1.],
                  [2., 0.], [-2., 0.], [0., 2.], [0., -2.]])
linear = KernelPCA(n_components=1, kernel="linear").fit_transform(rings)
rbf = KernelPCA(n_components=4, kernel="rbf", gamma=.5).fit_transform(rings)
gap = lambda scores, axis: abs(scores[:4, axis].mean() - scores[4:, axis].mean())
print(f"linear first axis separates rings: {bool(gap(linear, 0) > .1)}")
print(f"RBF fourth axis separates rings: {bool(gap(rbf, 3) > .1)}")

with warnings.catch_warnings():
    warnings.simplefilter("ignore", category=sklearn.exceptions.ConvergenceWarning)
    nmf9 = NMF(n_components=2, init="random", random_state=42, max_iter=300).fit(X)
print(f"NMF raw CI timings reconstructed: {bool(np.isfinite(nmf9.reconstruction_err_))}")
print(f"LDA with OS labels has two axes: {LinearDiscriminantAnalysis(n_components=2).fit_transform(Z, os_).shape == (len(os_), 2)}")
tsne9 = TSNE(n_components=2, perplexity=3, random_state=42, max_iter=300,
             learning_rate=200, method="exact").fit_transform(Z[:12])
print(f"t-SNE on 12 jobs is finite: {bool(np.isfinite(tsne9).all())}")

# Lesson 10: the chain's exact answers, then the casino replayed from the course's generator and decoded
# with numpy in log space.
print("\n== lesson 10")
market = np.array([[.9, .075, .025], [.15, .8, .05], [.25, .25, .5]])
system = market.T - np.eye(3)
system[-1] = 1
stationary = np.linalg.solve(system, np.array([0., 0., 1.]))
print(f"stationary distribution: {np.round(stationary, 4).tolist()}")
passage = np.linalg.solve(np.eye(2) - market[:2, :2], np.ones(2))
print(f"mean first passage to state 2: {np.round([*passage, 1 + market[2, :2] @ passage], 4).tolist()}")


def uniforms(seed):
    for x in xorshift(seed):
        yield (x >> 11) / 2 ** 53


def pick(p, u):
    total = 0.0
    for i, pi in enumerate(p):
        total += pi
        if u < total:
            return i
    return len(p) - 1


init10 = np.array([.5, .5])
trans10 = np.array([[.95, .05], [.1, .9]])
emit10 = np.array([[1 / 6] * 6, [.1] * 5 + [.5]])
draw10 = uniforms(10)
truth, rolls = [], []
for t in range(1000):
    state = pick(init10 if t == 0 else trans10[truth[-1]], next(draw10))
    truth.append(state)
    rolls.append(pick(emit10[state], next(draw10)))
truth, rolls = np.array(truth), np.array(rolls)


def runs(path, state=1):
    return int(np.sum((path == state) & np.concatenate(([True], path[:-1] != state))))


print(f"casino: {int(np.sum(truth == 1))} loaded rolls in {runs(truth)} runs; {int(np.sum(rolls == 5))} sixes")

with np.errstate(divide="ignore"):
    log_init, log_trans, log_emit = np.log(init10), np.log(trans10), np.log(emit10)


def log_alpha(obs, li, lt, le):
    la = np.empty((len(obs), len(li)))
    la[0] = li + le[:, obs[0]]
    for t in range(1, len(obs)):
        la[t] = np.logaddexp.reduce(la[t - 1][:, None] + lt, axis=0) + le[:, obs[t]]
    return la


def log_beta(obs, lt, le):
    lb = np.zeros((len(obs), lt.shape[0]))
    for t in range(len(obs) - 2, -1, -1):
        lb[t] = np.logaddexp.reduce(lt + le[:, obs[t + 1]] + lb[t + 1], axis=1)
    return lb


def viterbi(obs, li, lt, le):
    delta = li + le[:, obs[0]]
    back = []
    for t in range(1, len(obs)):
        scores = delta[:, None] + lt
        back.append(np.argmax(scores, axis=0))
        delta = scores.max(axis=0) + le[:, obs[t]]
    path = [int(np.argmax(delta))]
    for b in reversed(back):
        path.append(int(b[path[-1]]))
    return np.array(path[::-1])


la10 = log_alpha(rolls, log_init, log_trans, log_emit)
print(f"ln P(rolls): {np.logaddexp.reduce(la10[-1]):.4f}")
best = viterbi(rolls, log_init, log_trans, log_emit)
print(f"Viterbi: agreement with the true states {np.mean(best == truth):.3f}; {runs(best)} loaded runs")
gamma10 = la10 + log_beta(rolls, log_trans, log_emit)
posterior = np.argmax(gamma10, axis=1)
print(f"posterior decoding: agreement with the true states {np.mean(posterior == truth):.3f}; "
      f"{runs(posterior)} loaded runs")

with np.errstate(divide="ignore"):
    trap_i = np.log([.4, .3, .3])
    trap_t = np.log([[0., 0., 1.], [0., 1., 0.], [0., 1., 0.]])
    trap_e = np.zeros((3, 1))
trap_obs = np.array([0, 0])
trap_gamma = log_alpha(trap_obs, trap_i, trap_t, trap_e) + log_beta(trap_obs, trap_t, trap_e)
print(f"trap: posterior argmax {np.argmax(trap_gamma, axis=1).tolist()}, "
      f"Viterbi {viterbi(trap_obs, trap_i, trap_t, trap_e).tolist()}")

# Lesson 11: the sizing formulas and the count-min binomial model recomputed, and the hand HyperLogLog replayed:
# splitmix64 and the estimator are plain arithmetic, so numpy lands on the same estimates as Rust. IX's
# structures hash with Rust's DefaultHasher, which this check does not replay.
print("\n== lesson 11")
bits11 = math.ceil(-10_000 * math.log(0.01) / math.log(2) ** 2)
hashes11 = math.ceil(bits11 / 10_000 * math.log(2))
theory11 = [(1 - math.exp(-hashes11 * n / bits11)) ** hashes11 for n in (10_000, 20_000)]
print(f"Bloom sizing: m = {bits11}, k = {hashes11}; theory at 1x and 2x capacity {theory11[0]:.5f}, {theory11[1]:.5f}")


def log_binomial_pmf(n, q, j):
    return math.lgamma(n + 1) - math.lgamma(j + 1) - math.lgamma(n - j + 1) + j * math.log(q) + (n - j) * math.log1p(-q)


row_tail = sum(math.exp(log_binomial_pmf(9_999, 0.01, j)) for j in range(101, 10_000))
print(f"count-min binomial model: {row_tail ** 3:.4f}")

U64 = np.uint64


def splitmix64(x):
    with np.errstate(over="ignore"):
        z = x + U64(0x9E3779B97F4A7C15)
        z = (z ^ (z >> U64(30))) * U64(0xBF58476D1CE4E5B9)
        z = (z ^ (z >> U64(27))) * U64(0x94D049BB133111EB)
    return z ^ (z >> U64(31))


def bit_length(x):
    # exact for every uint64, unlike a float log2
    length = np.zeros(x.shape, dtype=np.int64)
    x = x.copy()
    for shift in (32, 16, 8, 4, 2, 1):
        big = x >= (U64(1) << U64(shift))
        length[big] += shift
        x[big] >>= U64(shift)
    return length + (x > 0)


def hll_count(hashes, p=10):
    m = 1 << p
    registers = np.zeros(m, dtype=np.int64)
    rank = 64 - p - bit_length(hashes >> U64(p)) + 1
    np.maximum.at(registers, (hashes & U64(m - 1)).astype(np.int64), rank)
    raw = 0.7213 / (1 + 1.079 / m) * m * m / np.sum(2.0 ** -registers)
    zeros = int(np.sum(registers == 0))
    return m * math.log(m / zeros) if raw <= 2.5 * m and zeros > 0 else raw


def hll_errors(sets, per_set):
    return np.array([hll_count(splitmix64(np.arange(t * per_set, (t + 1) * per_set, dtype=U64))) / per_set - 1
                     for t in range(sets)])


errors11 = hll_errors(100, 100_000)
print(f"hand HyperLogLog, 100 sets of 100000: RMS {np.sqrt(np.mean(errors11 ** 2)):.4f}, "
      f"mean {np.mean(errors11):.4f}, worst {np.max(np.abs(errors11)):.4f}")
for n in (500, 2_000, 2_560, 3_000, 4_000, 6_000, 10_000):
    errors11 = hll_errors(100, n)
    print(f"  n = {n:>6}: mean {np.mean(errors11):>7.4f}, RMS {np.sqrt(np.mean(errors11 ** 2)):.4f}")

# Lesson 12: IX's linear regression example rebuilt, its least-squares fit and conditioning, the closed-form
# gradient at w = 0, the example's Adam loop, and the gradient of sum c_k |FFT(x)_k| from numpy's FFT.
print("\n== lesson 12")
x12 = np.array([[((((i * 3 + j) * 1103515245 + 12345) >> 16) & 0x7FFF) / 32767.0 * 2 - 1 for j in range(3)]
                for i in range(20)])
noise12 = np.array([((((i * 7919 + 31) >> 16) & 0x7FFF) / 32767.0 - 0.5) * 0.02 for i in range(20)])
y12 = np.array([0.1 + sum(x12[i, j] * wj for j, wj in enumerate((0.5, -0.3, 0.8))) + noise12[i] for i in range(20)])
gap12 = x12[:, 2] - x12[:, 0]
print(f"x[i, 2] - x[i, 0]: min {gap12.min():.6f}, max {gap12.max():.6f}")
design12 = np.hstack([x12, np.ones((20, 1))])
sv12 = np.linalg.svd(design12, compute_uv=False)
print(f"singular values of [x 1]: {np.array2string(sv12, precision=6)}, condition number {sv12[0] / sv12[-1]:.0f}")
theta12 = np.linalg.lstsq(design12, y12, rcond=None)[0]
mse12 = np.mean((design12 @ theta12 - y12) ** 2)
print(f"least squares: w {np.array2string(theta12[:3], precision=6)}, b {theta12[3]:.6f}, "
      f"w0 + w2 = {theta12[0] + theta12[2]:.6f}, mean squared error below 1e-12: {mse12 < 1e-12}")
r12 = -y12
print(f"at w = 0, b = 0: loss {np.mean(r12 ** 2):.6f}, dL/dw {np.array2string(2 / 20 * x12.T @ r12, precision=6)}, "
      f"dL/db {2 / 20 * r12.sum():.6f}")


def adam12(steps=200, rate=0.05, b1=0.9, b2=0.999, eps=1e-8):
    theta, m, v, first = np.zeros(4), np.zeros(4), np.zeros(4), None
    for step in range(1, steps + 1):
        r = design12 @ theta - y12
        if first is None and np.mean(r ** 2) < 0.01:
            first = step
        g = 2 / 20 * design12.T @ r
        m = b1 * m + (1 - b1) * g
        v = b2 * v + (1 - b2) * g * g
        theta = theta - rate * (m / (1 - b1 ** step)) / (np.sqrt(v / (1 - b2 ** step)) + eps)
    return theta, first


theta12, first12 = adam12()
print(f"Adam, 200 steps: w {np.array2string(theta12[:3], precision=6)}, b {theta12[3]:.6f}, "
      f"loss below 0.01 first at step {first12}")
u12 = (splitmix64(np.arange(2027, 2027 + 128, dtype=U64)) >> U64(11)).astype(np.float64) / 2.0 ** 53
sig12, c12 = u12[:64] * 2 - 1, u12[64:]
spec12 = np.fft.fft(sig12)
grad12 = 64 * np.real(np.fft.ifft(c12 * spec12 / np.abs(spec12)))


def fft_loss12(s):
    return np.sum(c12 * np.abs(np.fft.fft(s)))


fd12 = np.array([(fft_loss12(sig12 + 1e-5 * e) - fft_loss12(sig12 - 1e-5 * e)) / 2e-5 for e in np.eye(64)])
print(f"FFT loss, numpy: dL/dx first four {np.array2string(grad12[:4], precision=6)}, "
      f"central differences within 1e-6: {np.max(np.abs(fd12 - grad12)) < 1e-6}")

print("\n== lesson 13")


def rng13(seed, n, start=0):
    """Draws start to start + n of the course's Rng(seed): splitmix64 of seed + 1, seed + 2, ..., top 53 bits"""
    counters = np.arange(seed + 1 + start, seed + 1 + start + n, dtype=U64)
    return (splitmix64(counters) >> U64(11)).astype(np.float64) / 2.0 ** 53


u13 = rng13(13, 84) * 2 - 1
q13, k13, v13 = (u13[i * 24:(i + 1) * 24].reshape(2, 4, 3) for i in range(3))
scores13 = q13 @ k13.transpose(0, 2, 1) / np.sqrt(3)
w13 = np.exp(scores13 - scores13.max(axis=2, keepdims=True))
w13 /= w13.sum(axis=2, keepdims=True)
out13 = w13 @ v13
print(f"attention, batch 0, query 0: weights {np.array2string(w13[0, 0], precision=6)}, "
      f"output {np.array2string(out13[0, 0], precision=6)}")
x13 = u13[72:84].reshape(2, 6) * 3 + 1
ln13 = (x13 - x13.mean(axis=1, keepdims=True)) / np.sqrt(x13.var(axis=1, keepdims=True) + 1e-5)
print(f"layer norm, token 0: {np.array2string(ln13[0], precision=6)}")
for d13 in [4, 16, 64, 256]:
    dots13, largest13 = [], np.zeros(2)
    for chunk in range(8):
        # 250 queries at a time: each draws q, then the 16 keys, d components each
        block = ((rng13(7, 250 * 17 * d13, chunk * 250 * 17 * d13) * 2 - 1) * np.sqrt(3)).reshape(250, 17, d13)
        dots = np.einsum("tkd,td->tk", block[:, 1:, :], block[:, 0, :])
        dots13.append(dots)
        for i, s in enumerate((1, 1 / np.sqrt(d13))):
            largest13[i] += np.sum(1 / np.exp((dots - dots.max(axis=1, keepdims=True)) * s).sum(axis=1))
    print(f"d {d13}: var(q.k) {np.concatenate(dots13).var():.1f}, largest of 16 weights unscaled "
          f"{largest13[0] / 2000:.3f}, scaled {largest13[1] / 2000:.3f}")
spread13 = np.random.default_rng(13).uniform(-1, 1, 1_000_000).std()
print(f"numpy's own U(-1, 1), a million draws: std {spread13:.4f}, 1/sqrt(3) = {1 / np.sqrt(3):.4f}")

print("\n== lesson 14")
q14 = np.zeros((25, 4))
for _ in range(200):
    v14 = q14.max(axis=1)
    new14 = np.zeros((25, 4))
    for r in range(5):
        for c in range(5):
            if (r, c) == (4, 4):
                continue
            for a, (nr, nc) in enumerate([(max(r - 1, 0), c), (r, min(c + 1, 4)), (min(r + 1, 4), c), (r, max(c - 1, 0))]):
                new14[r * 5 + c, a] = 10.0 if (nr, nc) == (4, 4) else -1.0 + 0.99 * v14[nr * 5 + nc]
    q14 = new14
print(f"value iteration, 5 x 5 GridWorld, gamma 0.99: V*(start) {q14[0].max():.6f}")
best14 = [(rng13(t * 1_000_000, 120).reshape(10, 12).sum(axis=1) - 6).max() for t in range(2000)]
print(f"testbed, 2000 tasks from the course's Rng: mean of the best arm's mean {np.mean(best14):.3f}")
for horizon14 in [10_000, 100_000]:
    bound14 = 8 * math.log(horizon14) * (1 / 0.1 + 1 / 0.2) + (1 + math.pi ** 2 / 3) * 0.3
    print(f"Auer et al. bound at T = {horizon14}: {bound14:.1f}")

print("\n== lesson 15")
# scipy is not pinned here: it comes with scikit-learn 1.8.0, and the lines below print nothing that differs
# between its recent versions
from scipy import linalg as spl, signal as sps  # noqa: E402


def taps15(v):
    return "[" + ", ".join(f"{x:.9f}" for x in v) + "]"


def decade15(x):
    e = math.floor(math.log10(x))
    return f"1e{e} to 1e{e + 1}"


x15 = rng13(15, 12 * 16384).reshape(16384, 12).sum(axis=1) - 6
w15 = np.hanning(512)
seg15 = np.lib.stride_tricks.sliding_window_view(x15, 512)[::256]
ix15 = (np.abs(np.fft.rfft(seg15 * w15, axis=1)) ** 2 / (w15 ** 2).sum()).mean(axis=0) / 1000
_, sp15 = sps.welch(x15, fs=1000, window=w15, nperseg=512, noverlap=256, detrend=False, scaling="density")
print(f"Welch, {len(seg15)} segments: integral / variance, IX's convention {ix15.sum() * 1000 / 512 / x15.var():.3f}, "
      f"scipy.signal.welch {sp15.sum() * 1000 / 512 / x15.var():.3f}")
r15 = sp15 / ix15
print(f"scipy / IX's convention: bins 1 to 255 within 1e-9 of 2: {bool(np.all(np.abs(r15[1:256] / 2 - 1) < 1e-9))}; "
      f"bins 0 and 256: {r15[0]:.6f}, {r15[256]:.6f}")


def ix_fft15(x):
    """IX's fft_in_place: bit reversal, then one cos and one sin per stage and the twiddles by recurrence"""
    n = len(x)
    bits = n.bit_length() - 1
    data = x[[int(format(i, f"0{bits}b")[::-1], 2) for i in range(n)]].astype(np.complex128)
    length = 2
    while length <= n:
        half = length // 2
        angle = -2.0 * math.pi / length
        base = complex(math.cos(angle), math.sin(angle))
        w = [1 + 0j]
        for _ in range(half - 1):
            w.append(w[-1] * base)
        rows = data.reshape(-1, length)
        even = rows[:, :half].copy()
        odd = rows[:, half:] * np.array(w)
        rows[:, :half] = even + odd
        rows[:, half:] = even - odd
        length *= 2
    return data


for log15 in [8, 16]:
    u15 = rng13(15_200 + log15, 1 << log15) * 2 - 1
    ref15 = np.fft.fft(u15)
    err15 = np.linalg.norm(ix_fft15(u15) - ref15) / np.linalg.norm(ref15)
    print(f"IX's FFT recurrence in numpy against numpy.fft, N = 2^{log15}: {decade15(err15)}")

b15, a15 = sps.butter(2, 0.2)
print(f"scipy.signal.butter(2, 0.2): b {taps15(b15)}, a {taps15(a15)}")
p15 = spl.solve_discrete_are(np.array([[1.0]]), np.array([[1.0]]), np.array([[0.01]]), np.array([[1.0]]))[0, 0]
print(f"scipy.linalg.solve_discrete_are, q 0.01, r 1: prior variance {p15:.9f}, gain {p15 / (p15 + 1):.9f}")
h15 = sps.firwin(65, 0.2, window="hamming", scale=False)
print(f"scipy.signal.firwin(65, 0.2, hamming, unscaled): centre tap {h15[32]:.9f}, sum of the taps {h15.sum():.9f}")
try:
    sps.firwin(32, 0.5, pass_zero=False)
    print("scipy.signal.firwin designs a 32-tap high-pass")
except ValueError:
    print("scipy.signal.firwin refuses a 32-tap high-pass: ValueError")
ones15 = [float(f(1)[0]) for f in (np.hanning, np.hamming, np.blackman, np.bartlett)] + [float(np.kaiser(1, 5)[0])]
print(f"numpy windows of length 1 (hanning, hamming, blackman, bartlett, kaiser 5): {ones15}")

print("\n== lesson 16")
from scipy.sparse import coo_matrix  # noqa: E402
from scipy.sparse.csgraph import shortest_path  # noqa: E402

# The mazes of lesson 16, rebuilt from the course's Rng: a cell is a wall when its draw is below 0.25, cells
# row by row, corners kept open. SciPy's breadth-first shortest paths replace ix-graph's Dijkstra.
size16 = 30
reachable16, total16 = 0, 0.0
for index16 in range(100):
    open16 = rng13(16_000 + index16, size16 * size16) >= 0.25
    open16[0] = open16[-1] = True
    cells16 = np.arange(size16 * size16).reshape(size16, size16)
    pairs16 = np.concatenate([
        np.stack([cells16[:, :-1].ravel(), cells16[:, 1:].ravel()], axis=1),
        np.stack([cells16[:-1, :].ravel(), cells16[1:, :].ravel()], axis=1),
    ])
    pairs16 = pairs16[open16[pairs16[:, 0]] & open16[pairs16[:, 1]]]
    graph16 = coo_matrix((np.ones(len(pairs16)), (pairs16[:, 0], pairs16[:, 1])), shape=(size16 ** 2, size16 ** 2))
    d16 = shortest_path(graph16, directed=False, unweighted=True, indices=0)[-1]
    if np.isfinite(d16):
        reachable16 += 1
        total16 += d16
print(f"100 mazes of 30 x 30, walls 0.25: far corner reachable {reachable16}, total optimal cost {total16:.0f}")


def attacking16(rows):
    return sum(1 for i in range(8) for j in range(i + 1, 8)
               if rows[i] == rows[j] or abs(rows[i] - rows[j]) == j - i)


def climb16(rows):
    """Steepest ascent as IX's hill_climbing: the last best of the 56 neighbours, moved to only if strictly
    better. Returns (attacking pairs at the end, steps)."""
    rows, h, steps = list(rows), attacking16(rows), 0
    while True:
        best, best_h = None, None
        for column in range(8):
            for row in range(8):
                if row != rows[column]:
                    candidate = rows.copy()
                    candidate[column] = row
                    ch = attacking16(candidate)
                    if best_h is None or ch <= best_h:
                        best, best_h = candidate, ch
        if best_h < h:
            rows, h, steps = best, best_h, steps + 1
        else:
            return h, steps


boards16 = np.floor(rng13(16_800, 8 * 1000) * 8).astype(int).reshape(1000, 8)
runs16 = [climb16(b) for b in boards16]
solved16 = [s for h, s in runs16 if h == 0]
stuck16 = [s for h, s in runs16 if h > 0]
print(f"8 queens, 1000 boards, steepest ascent with the last best neighbour: solved {len(solved16)}, "
      f"mean steps {np.mean(solved16):.2f} when solved, {np.mean(stuck16):.2f} when stuck")
restart16 = np.floor(rng13(16_900, 8 * 21 * 100) * 8).astype(int).reshape(100, 21, 8)
wins16 = sum(any(climb16(b)[0] == 0 for b in run[1:]) for run in restart16)
print(f"8 queens, 100 runs of 20 restarts: solved {wins16}")

print("\n== lesson 17")
# The Pareto sets of lesson 17, rebuilt from the course's Rng: 100 sets of 200 points, drawn point by point,
# Rng(17_702) in 2 dimensions and Rng(17_703) in 3. Front 0 by brute force: the points no other point
# dominates, every objective minimized.
for dims17 in (2, 3):
    sets17 = rng13(17_700 + dims17, 100 * 200 * dims17).reshape(100, 200, dims17)
    sizes17 = []
    for p17 in sets17:
        le17 = (p17[:, None, :] <= p17[None, :, :]).all(axis=2)
        lt17 = (p17[:, None, :] < p17[None, :, :]).any(axis=2)
        sizes17.append(int((~(le17 & lt17).any(axis=0)).sum()))
    print(f"{dims17} dimensions, 100 sets of 200 uniform points: mean size of front 0 {np.mean(sizes17):.3f}")

# BLX-alpha on independent standard normal parents, with numpy's own generator: the child's variance is
# 1/2 + (1 + 2 alpha)^2 / 6, 7/6 at alpha = 0.5 and 1 at alpha = (sqrt(3) - 1) / 2.
g17 = np.random.default_rng(17)
a17, b17 = g17.standard_normal(1_000_000), g17.standard_normal(1_000_000)
for alpha17 in (0.5, (np.sqrt(3) - 1) / 2):
    d17 = np.abs(a17 - b17)
    child17 = g17.uniform(np.minimum(a17, b17) - alpha17 * d17, np.maximum(a17, b17) + alpha17 * d17)
    print(f"BLX-{alpha17:.3f}, 10^6 children of N(0, 1) parents: variance {child17.var():.3f}, "
          f"formula {0.5 + (1 + 2 * alpha17) ** 2 / 6:.3f}")

print("\n== lesson 18")
from scipy.stats import norm  # noqa: E402


def irwin18(u):
    """The course's approximate normal from its last axis of 12 uniforms, summed in order as Rust's sum does"""
    s = np.zeros(u.shape[:-1])
    for k in range(12):
        s = s + u[..., k]
    return s - 6


# The test set of lesson 18, rebuilt from Rng(18_100) point by point: x = y mu + n in 100 dimensions,
# classes alternating +1 and -1, and the linear model w = mu = 0.2. FGSM from the loss gradient's sign.
y18 = np.where(np.arange(2000) % 2 == 0, 1.0, -1.0)
x18 = y18[:, None] * 0.2 + irwin18(rng13(18_100, 2000 * 100 * 12).reshape(2000, 100, 12))
w18 = np.full(100, 0.2)
m18 = y18 * (x18 @ w18)
g18 = (-y18 / (1 + np.exp(m18)))[:, None] * w18[None, :]
accuracy18 = [float(np.mean(y18 * ((x18 + eps * np.sign(g18)) @ w18) > 0)) for eps in (0.0, 0.1, 0.2, 0.3)]
print(f"FGSM against w = mu, numpy: accuracy at eps 0, 0.1, 0.2, 0.3: {' '.join(f'{a:.4f}' for a in accuracy18)}")

# cw_attack on this model as a scalar recurrence: the perturbation stays t times the unit vector -y w/|w|, so
# the margin is m - 2t, the objective |t| + c max(m - 2t, 0), and a step subtracts lr (sign(t) - 2c [m - 2t > 0]).
mc18 = m18[m18 > 0]
for c18 in (0.25, 1.0, 0.75):
    t18 = np.zeros_like(mc18)
    best18, best_t18 = np.full_like(mc18, np.inf), np.zeros_like(mc18)
    for _ in range(2000):
        loss18 = np.abs(t18) + c18 * np.maximum(mc18 - 2 * t18, 0)
        better18 = loss18 < best18
        best18, best_t18 = np.where(better18, loss18, best18), np.where(better18, t18, best_t18)
        t18 = t18 - 0.01 * (np.sign(t18) - 2 * c18 * (mc18 - 2 * t18 > 0))
    print(f"Carlini-Wagner as a scalar recurrence, c = {c18}: {len(mc18)} points, {int(np.sum(best_t18 == 0))} unchanged, "
          f"misclassified {np.mean(mc18 - 2 * best_t18 < 0):.4f}")

# Feature squeezing: Rng(18_600) values, Rng(18_601) signs, rounding half away from zero as Rust's f64::round
v18 = rng13(18_600, 100_000)
s18 = rng13(18_601, 100_000)
for bits18, eps18 in ((3, 0.05), (5, 0.01)):
    levels18 = 2 ** bits18 - 1
    moved18 = v18 + np.where(s18 < 0.5, -eps18, eps18)
    d18 = (np.floor(np.clip(moved18, 0, 1) * levels18 + 0.5) - np.floor(np.clip(v18, 0, 1) * levels18 + 0.5)) / levels18
    print(f"squeezing to {bits18} bits, eps {eps18}: changed {np.mean(d18 != 0):.4f}, mean |change| {np.mean(np.abs(d18)):.5f}, "
          f"root mean square {np.sqrt(np.mean(d18 ** 2)):.5f}")


# IX's probit, formula 26.2.23 of Abramowitz and Stegun, against scipy's norm.ppf
def probit18(p):
    t = np.sqrt(-2 * np.log(np.where(p < 0.5, p, 1 - p)))
    value = t - (2.515517 + 0.802853 * t + 0.010328 * t * t) / (1 + 1.432788 * t + 0.189269 * t * t + 0.001308 * t ** 3)
    return np.where(p < 0.5, -value, value)


pa18 = np.arange(501, 1000) / 1000
error18 = np.abs((probit18(pa18) - probit18(1 - pa18)) / 2 - (norm.ppf(pa18) - norm.ppf(1 - pa18)) / 2)
print(f"certified radius, sigma 1, p_A = 0.501 to 0.999: largest error against scipy {error18.max():.2e} "
      f"at p_A = {pa18[error18.argmax()]:.3f}")
clamped18 = np.array([1 - 1e-10, 1e-10])
print(f"logits (2, -1) clamped: IX's formula {(probit18(clamped18[:1]) - probit18(clamped18[1:]))[0] / 2:.4f}, "
      f"scipy {(norm.ppf(clamped18[0]) - norm.ppf(clamped18[1])) / 2:.4f}")

# Label flips: Rng(18_800) points around (-2, -2) and (2, 2), 100 labels picked by the first 100 places of a
# Fisher-Yates shuffle from Rng(18_801), and the k = 5 majority vote with ties in distance broken by index
f18 = irwin18(rng13(18_800, 1000 * 2 * 12).reshape(1000, 2, 12)) + np.where(np.arange(1000) % 2 == 1, 2.0, -2.0)[:, None]
labels18 = (np.arange(1000) % 2).astype(float)
order18 = np.arange(1000)
for i18, u18 in enumerate(rng13(18_801, 100)):
    j18 = i18 + int(u18 * (1000 - i18))
    order18[i18], order18[j18] = order18[j18], order18[i18]
noisy18 = labels18.copy()
noisy18[order18[:100]] = 1 - noisy18[order18[:100]]
dist18 = np.sqrt(((f18[:, None, :] - f18[None, :, :]) ** 2).sum(axis=2))
np.fill_diagonal(dist18, np.inf)
votes18 = noisy18[np.argsort(dist18, axis=1, kind="stable")[:, :5]].sum(axis=1)
flagged18 = (votes18 >= 5 - votes18) != (noisy18 >= 0.5)
found18 = int(flagged18[order18[:100]].sum())
print(f"label flips, numpy's 5 nearest neighbours: {found18} of 100 flipped labels found, {int(flagged18.sum()) - found18} others")

# Spectral signatures: Rng(18_802) rows of 10 features, 100 of class 0, 100 of class 1 moved by 3 on the first
# feature, then 5 of class 0 moved by 6 on the last; numpy's eigh for the top direction of each class
rows18 = irwin18(rng13(18_802, 205 * 10 * 12).reshape(205, 10, 12))
rows18[100:200, 0] += 3
rows18[200:, 9] += 6
classes18 = np.array([0] * 100 + [1] * 100 + [0] * 5)


def spectral18(n):
    flagged = []
    for c in (0, 1):
        idx = np.flatnonzero(classes18[:n] == c)
        centred = rows18[idx] - rows18[idx].mean(axis=0)
        scores = np.abs(centred @ np.linalg.eigh(centred.T @ centred)[1][:, -1])
        cutoff = np.sort(scores)[min(int(0.9 * len(idx)), len(idx) - 1)]
        flagged.append(idx[scores > cutoff])
    return flagged


clean18, poisoned18 = spectral18(200), spectral18(205)
print(f"spectral signatures with numpy's eigh: flagged per class {[len(f) for f in clean18]}; with the 5 shifted "
      f"points {[len(f) for f in poisoned18]}, shifted among them {int(np.sum(poisoned18[0] >= 200))}")


print("\n== lesson 19")
from itertools import combinations  # noqa: E402

from scipy.optimize import linear_sum_assignment  # noqa: E402
from scipy.sparse import csr_matrix  # noqa: E402
from scipy.sparse.csgraph import maximum_bipartite_matching, minimum_spanning_tree  # noqa: E402


def rips19(points, build_dim, max_radius):
    """Rips persistence over Z/2, written again with Python sets: simplices from itertools, faces by dictionary"""
    n = len(points)
    dist = np.sqrt(((points[:, None, :] - points[None, :, :]) ** 2).sum(axis=2))
    simplices = []
    for k in range(1, build_dim + 2):
        for s in combinations(range(n), k):
            value = max((dist[a, b] for a, b in combinations(s, 2)), default=0.0)
            if value <= max_radius:
                simplices.append((value, k, s))
    simplices.sort()
    index = {s: i for i, (_, _, s) in enumerate(simplices)}
    columns, pivot = [], {}
    for j, (_, k, s) in enumerate(simplices):
        col = {index[f] for f in combinations(s, k - 1)} if k > 1 else set()
        while col:
            low = max(col)
            if low not in pivot:
                pivot[low] = j
                break
            col ^= columns[pivot[low]]
        columns.append(col)
    diagrams = [[] for _ in range(build_dim + 1)]
    for j, col in enumerate(columns):
        if col:
            low = max(col)
            birth, death = simplices[low][0], simplices[j][0]
            if death - birth > 1e-15:
                diagrams[simplices[low][1] - 1].append((birth, death))
        elif j not in pivot:
            diagrams[simplices[j][1] - 1].append((simplices[j][0], math.inf))
    return diagrams


def essential19(diagram):
    return sum(1 for _, d in diagram if math.isinf(d))


def betti19(diagrams, r):
    return [sum(1 for b, d in dg if b <= r < d) for dg in diagrams]


def split19(diagram):
    return [p for p in diagram if math.isfinite(p[1])], sorted(p[0] for p in diagram if math.isinf(p[1]))


def costs19(d1, d2):
    """d1's points then a diagonal slot per point of d2, against d2's points then a slot per point of d1"""
    n1, n2 = len(d1), len(d2)
    c = np.full((n1 + n2, n1 + n2), np.inf)
    for i, (b, d) in enumerate(d1):
        for j, (b2, e2) in enumerate(d2):
            c[i, j] = max(abs(b - b2), abs(d - e2))
        c[i, n2 + i] = (d - b) / 2
    for j, (b, d) in enumerate(d2):
        c[n1 + j, j] = (d - b) / 2
    c[n1:, n2:] = 0.0
    return c


def bottleneck19(d1, d2):
    """The smallest cost at which scipy's maximum_bipartite_matching finds a perfect matching"""
    (f1, e1), (f2, e2) = split19(d1), split19(d2)
    if len(e1) != len(e2):
        return math.inf
    essential = max((abs(a - b) for a, b in zip(e1, e2)), default=0.0)
    c = costs19(f1, f2)
    candidates = np.unique(c[np.isfinite(c)])
    if len(candidates) == 0:
        return essential
    lo, hi = 0, len(candidates) - 1
    while lo < hi:
        mid = (lo + hi) // 2
        matching = maximum_bipartite_matching(csr_matrix((c <= candidates[mid]).astype(np.int8)), perm_type="column")
        if (matching >= 0).all():
            hi = mid
        else:
            lo = mid + 1
    return max(essential, float(candidates[lo]))


def wasserstein19(d1, d2, p):
    """scipy's linear_sum_assignment on the same matching problem"""
    (f1, e1), (f2, e2) = split19(d1), split19(d2)
    if len(e1) != len(e2):
        return math.inf
    c = costs19(f1, f2) ** p
    c[~np.isfinite(c)] = 1e9
    rows, cols = linear_sum_assignment(c)
    return (c[rows, cols].sum() + sum(abs(a - b) ** p for a, b in zip(e1, e2))) ** (1 / p)


def ix_bottleneck19(d1, d2):
    """IX's greedy: pad each list with the other's diagonal projections, sort both by persistence, pair by rank"""
    p1, p2 = list(d1), list(d2)
    p2 += [((b + d) / 2, (b + d) / 2) for b, d in d1 if math.isfinite(d)]
    p1 += [((b + d) / 2, (b + d) / 2) for b, d in d2 if math.isfinite(d)]
    p1.sort(key=lambda q: -abs(q[1] - q[0]))
    p2.sort(key=lambda q: -abs(q[1] - q[0]))
    return max((max(abs(a[0] - b[0]), abs(a[1] - b[1])) for a, b in zip(p1, p2)), default=0.0)


def ix_wasserstein19(d1, d2, p):
    """IX's matching: drop essential points, pad the shorter list, sort both by birth, pair by index"""
    p1 = [q for q in d1 if math.isfinite(q[1])]
    p2 = [q for q in d2 if math.isfinite(q[1])]
    while len(p1) < len(p2):
        b, d = p2[len(p1)]
        p1.append(((b + d) / 2, (b + d) / 2))
    while len(p2) < len(p1):
        b, d = p1[len(p2)]
        p2.append(((b + d) / 2, (b + d) / 2))
    p1.sort(key=lambda q: q[0])
    p2.sort(key=lambda q: q[0])
    return sum(max(abs(a[0] - b[0]), abs(a[1] - b[1])) ** p for a, b in zip(p1, p2)) ** (1 / p)


# The circle of Rng(19_100): 24 points at angles 2 pi i / 24 and radii 1 + 0.1 (2u - 1)
u19 = rng13(19_100, 24)
radius19 = 1 + 0.1 * (2 * u19 - 1)
angle19 = 2 * np.pi * np.arange(24) / 24
circle19 = np.stack([radius19 * np.cos(angle19), radius19 * np.sin(angle19)], axis=1)
d19 = rips19(circle19, 2, 2.5)
dist19 = np.sqrt(((circle19[:, None, :] - circle19[None, :, :]) ** 2).sum(axis=2))
deaths19 = np.sort([d for _, d in d19[0] if math.isfinite(d)])
loops19 = [(b, d) for b, d in d19[1] if d - b > 0.5]
print(f"circle, Python sets: H0 {len(deaths19)} finite pairs, {essential19(d19[0])} essential, deaths equal scipy's "
      f"minimum spanning tree: {np.array_equal(deaths19, np.sort(minimum_spanning_tree(dist19).data))}; "
      f"H1 {len(d19[1])} pairs, above persistence 0.5: born {loops19[0][0]:.4f}, dies {loops19[0][1]:.4f}")
top1_19, top3_19 = rips19(circle19, 1, 2.5)[1], rips19(circle19, 3, 2.5)[2]
print(f"top dimension, Python sets: built to edges, H1 {len(top1_19)} pairs, {essential19(top1_19)} essential; "
      f"to triangles, H2 {len(d19[2])} pairs, {essential19(d19[2])} essential; "
      f"to tetrahedra, H2 {len(top3_19)} pairs, {essential19(top3_19)} essential")
square19 = np.array([[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]])
print(f"unit square at 1.5, Python sets: built to edges {betti19(rips19(square19, 1, 1.5), 1.5)}, "
      f"to triangles {betti19(rips19(square19, 2, 1.5), 1.5)}, to tetrahedra {betti19(rips19(square19, 3, 1.5)[:3], 1.5)}")

a1_19, a2_19 = [(0.0, 2.0), (10.0, 11.0)], [(10.0, 12.0), (0.0, 1.0)]
b1_19, b2_19 = [(0.0, 10.0), (1.0, 2.0)], [(1.0, 10.0), (0.0, 2.0)]
print(f"hand-made, scipy: bottleneck IX {ix_bottleneck19(a1_19, a2_19):.4f}, exact {bottleneck19(a1_19, a2_19):.4f}; "
      f"W1 IX {ix_wasserstein19(b1_19, b2_19, 1):.4f}, exact {wasserstein19(b1_19, b2_19, 1):.4f}; "
      f"W2 IX {ix_wasserstein19(b1_19, b2_19, 2):.4f}, exact {wasserstein19(b1_19, b2_19, 2):.4f}; "
      f"(0, inf) against nothing: IX {ix_bottleneck19([(0.0, math.inf)], []):.4f}, "
      f"exact {bottleneck19([(0.0, math.inf)], [])}")

# 1,000 pairs of 5-point diagrams from Rng(19_400): each point draws its birth, then its persistence
r19 = rng13(19_400, 1000 * 2 * 5 * 2).reshape(1000, 2, 5, 2)
counts19 = [0, 0, 0, 0]
for pair19 in r19:
    e1_19, e2_19 = ([(float(u[0]), float(u[0] + u[1])) for u in diagram] for diagram in pair19)
    for k19, (ix19, exact19) in enumerate([(ix_bottleneck19(e1_19, e2_19), bottleneck19(e1_19, e2_19)),
                                           (ix_wasserstein19(e1_19, e2_19, 1), wasserstein19(e1_19, e2_19, 1))]):
        counts19[2 * k19] += ix19 >= exact19 - 1e-12
        counts19[2 * k19 + 1] += ix19 > exact19 + 1e-9
print(f"random diagrams, scipy: bottleneck, IX at least exact {counts19[0]}, above {counts19[1]}; "
      f"W1, IX at least exact {counts19[2]}, above {counts19[3]}")

# Stability: cloud t from Rng(19_500 + t), 24 points in the unit square, each moved by 0.01 along (u, v)/|(u, v)|
within19 = above19 = 0
for t19 in range(50):
    r = rng13(19_500 + t19, 96)
    points19 = r[:48].reshape(24, 2)
    uv19 = 2 * r[48:].reshape(24, 2) - 1
    norm19 = np.sqrt(uv19[:, 0] * uv19[:, 0] + uv19[:, 1] * uv19[:, 1])
    moved19 = points19 + 0.01 * (uv19 / norm19[:, None])
    h1a19, h1b19 = rips19(points19, 2, 1.5)[1], rips19(moved19, 2, 1.5)[1]
    within19 += bottleneck19(h1a19, h1b19) <= 0.02 + 1e-12
    above19 += ix_bottleneck19(h1a19, h1b19) > 0.02
print(f"stability, Python sets and scipy: exact bottleneck at most 0.02 in {within19} of 50, IX's above 0.02 in {above19}")

print("\n== lesson 20")
# The kNN shader's loop again, vectorised in float32: references Rng(20_200), queries Rng(20_201), 8 coordinates.
# Distances add the squared differences one coordinate after the other, as the shader and batch_knn_cpu do.
refs20 = rng13(20_200, 1000 * 8).astype(np.float32).reshape(1000, 8)
queries20 = rng13(20_201, 1000 * 8).astype(np.float32).reshape(1000, 8)


def distances20(q, r):
    acc = np.zeros((len(q), len(r)), dtype=np.float32)
    for d in range(q.shape[1]):
        diff = q[:, None, d] - r[None, :, d]
        acc = acc + diff * diff
    return np.sqrt(acc)


def port20(dist, k):
    """Thread t keeps the first nearest of references t, t + 256, ...; the candidates are sorted, k kept"""
    n_q, n = dist.shape
    rows = -(-n // 256)
    padded = np.full((n_q, rows * 256), np.inf, dtype=np.float32)
    padded[:, :n] = dist
    blocks = padded.reshape(n_q, rows, 256)
    row = blocks.argmin(axis=1)
    best = np.take_along_axis(blocks, row[:, None, :], axis=1)[:, 0, :]
    index = row * 256 + np.arange(256)
    order = np.argsort(best, axis=1, kind="stable")[:, :k]
    return np.take_along_axis(index, order, axis=1)


def exact20(dist, k):
    return np.argsort(dist, axis=1, kind="stable")[:, :k]


def differ20(a, b):
    return sum(set(x) != set(y) for x, y in zip(a.tolist(), b.tolist()))


def p_wrong20(n, k):
    e = [1] + [0] * k
    for t in range(256):
        size = n // 256 + (t < n % 256)
        for j in range(k, 0, -1):
            e[j] += e[j - 1] * size
    return 1 - e[k] / math.comb(n, k)


d20 = distances20(queries20, refs20)
d20_256 = distances20(queries20, refs20[:256])
recovered20 = sum(len(set(x) & set(y)) for x, y in zip(exact20(d20, 10).tolist(), port20(d20, 10).tolist()))
print(f"kNN shader loop, numpy float32: P(wrong) {p_wrong20(1000, 10):.4f}; queries that differ {differ20(port20(d20, 10), exact20(d20, 10))}, "
      f"k = 1 {differ20(port20(d20, 1), exact20(d20, 1))}, first 256 references {differ20(port20(d20_256, 10), exact20(d20_256, 10))}; "
      f"neighbours recovered {recovered20} of 10000")


def cosine20(a, b):
    """cosine_similarity_cpu in float32: sums one term after the other, zero below a norm of 1e-10"""
    dot = na = nb = np.float32(0)
    for x, y in zip(a, b):
        dot, na, nb = dot + x * y, na + x * x, nb + y * y
    na, nb = np.sqrt(na), np.sqrt(nb)
    return np.float32(0) if na < np.float32(1e-10) or nb < np.float32(1e-10) else dot / (na * nb)


def batch20(a, b):
    """batch_top_k's normalisation in float32: zero unless the product of the norms is above 1e-10"""
    dot = na = nb = np.float32(0)
    for x, y in zip(a, b):
        dot, na, nb = dot + x * y, na + x * x, nb + y * y
    denom = np.sqrt(na) * np.sqrt(nb)
    return dot / denom if denom > np.float32(1e-10) else np.float32(0)


a20 = np.array([1e-6, 2e-6, 2e-6], dtype=np.float32)
b20 = np.float32(2) * a20
z20 = np.zeros(3, dtype=np.float32)
print(f"thresholds, numpy float32: cosine {cosine20(a20, b20):.6f}, batch {batch20(a20, b20):.6f}, cosine of zero {cosine20(z20, z20):.6f}")
print(f"limits: largest n with 4 n^2 <= 128 MiB {math.isqrt((128 << 20) // 4)}; 10000 x 10000 x 4 = {4 * 10000 ** 2} bytes")

# Lesson 21: scikit-learn's macro average against the tool's, FNV-1a 64 of the lock file's canonical args, and a
# linear regression's predictions after the scaler is fitted on all rows or on the training rows only
print("\n== lesson 21")
y21 = [1, 2, 1, 2, 2]
p, r, f, _ = precision_recall_fscore_support(y21, y21, average="macro")
print(f"labels 1 and 2, all right: scikit-learn macro {p:.16g} {r:.16g} {f:.16g}")
p, r, f, _ = precision_recall_fscore_support(y21, y21, labels=[0, 1, 2], average="macro", zero_division=0)
print(f"the same with labels=[0, 1, 2], as the tool counts them: {p:.16g} {r:.16g} {f:.16g}")


def fnv1a64(data):
    h = 0xcbf29ce484222325
    for b in data:
        h = ((h ^ b) * 0x100000001b3) % (1 << 64)
    return h


canon21 = b'{"data":[1.0,2.0]}'
print(f"FNV-1a 64 of {canon21.decode()}: fnv1a64:{fnv1a64(canon21):016x}")
whole21 = sorted({int(s) for s in seconds})
print(f"build_seconds: {len(whole21)} distinct whole values, largest {whole21[-1]}: the tool counts {whole21[-1] + 1} classes")
raw21 = LinearRegression().fit(pages[train], seconds[train]).predict(pages[test])
all21 = StandardScaler().fit(pages)
fit21 = StandardScaler().fit(pages[train])
gap21 = max(
    np.abs(LinearRegression().fit(s.transform(pages[train]), seconds[train]).predict(s.transform(pages[test])) - raw21).max()
    for s in (all21, fit21))
print(f"linear regression, chronological split: predictions after either scaler within 1e-9 of the raw feature's: {'yes' if gap21 < 1e-9 else 'no'}")
