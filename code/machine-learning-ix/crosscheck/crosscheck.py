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
