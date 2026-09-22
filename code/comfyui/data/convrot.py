"""What the `convrot` flag of an int8 checkpoint does, in arithmetic.

Lesson 8 reads `{"format": "int8_tensorwise", "convrot": true, "convrot_groupsize": 256}`
out of a Z-Image-Turbo checkpoint's `comfy_quant` tensors and could only guess at
the name. comfy-kitchen's `_build_hadamard` builds a *regular* Hadamard matrix —
Kronecker powers of

    [[1, 1, 1, -1], [1, 1, -1, 1], [1, -1, 1, 1], [-1, 1, 1, 1]] / sqrt(size)

so the size is a power of 4 — and rotates each group of `convrot_groupsize`
input channels by it: the weight offline, `W @ H.T`, the activations online,
`x @ H`, fused into the row-wise quantizer.

This script rebuilds that matrix and prints what makes the trick work:

1. the matrix is symmetric and orthogonal, so it is its own inverse, and
   `(x @ H) @ (W @ H.T).T == x @ W.T` exactly — the rotation costs no accuracy;
2. a rotation mixes each group of 256 channels, so one outlier weight is spread
   over the group instead of setting the scale of the whole row alone; the
   int8 round-trip error drops.

Printed as information on each operating system, never compared: the two error
figures depend on the machine's floating point. Only the orders of magnitude
carry the point.
"""
import torch

GROUP = 256
ROWS, COLS = 512, 1024


def hadamard(size, dtype=torch.float32):
    """comfy-kitchen's regular Hadamard: Kronecker powers of a symmetric 4x4 block."""
    h4 = torch.tensor([[1, 1, 1, -1], [1, 1, -1, 1], [1, -1, 1, 1], [-1, 1, 1, 1]], dtype=dtype)
    h = h4
    while h.shape[0] < size:
        h = torch.kron(h, h4)
    return h / size ** 0.5


def rotate(tensor, h, group):
    """Rotate each group of `group` columns by h, as comfy-kitchen does."""
    rows, cols = tensor.shape
    return torch.matmul(tensor.reshape(rows, cols // group, group), h).reshape(rows, cols)


def int8_roundtrip(weight):
    """Row-wise int8, the scale comfy-kitchen uses when `per_channel` is on."""
    scale = weight.abs().amax(dim=-1, keepdim=True) / 127.0
    return torch.round(weight / scale).clamp(-127, 127) * scale


def relative_error(approximation, exact):
    return float((approximation - exact).norm() / exact.norm())


def main():
    h = hadamard(GROUP, torch.float64)
    identity = torch.eye(GROUP, dtype=torch.float64)
    print('info convrot Hadamard   %d x %d, symmetric %s, max |H @ H - I| %.2e'
          % (GROUP, GROUP, bool(torch.equal(h, h.T)), float((h @ h - identity).abs().max())))

    # A weight the way quantization papers describe one: small values, and in
    # every row one channel tens of times larger, which alone sets the scale.
    generator = torch.Generator().manual_seed(42)
    weight = torch.randn(ROWS, COLS, generator=generator, dtype=torch.float64) * 0.02
    for row in range(ROWS):
        weight[row, (row * 7) % COLS] = 0.02 * 40 * (1 - 2 * (row % 2))

    h = h.to(weight.dtype)
    weight_rotated = rotate(weight, h.T, GROUP)
    activation = torch.randn(8, COLS, generator=generator, dtype=weight.dtype)
    rotated_product = rotate(activation, h, GROUP) @ weight_rotated.T
    print('info convrot exactness  max |(x @ H) @ (W @ H.T).T - x @ W.T| %.2e'
          % float((rotated_product - activation @ weight.T).abs().max()))

    plain = int8_roundtrip(weight)
    unrotated = rotate(int8_roundtrip(weight_rotated), h, GROUP)
    print('info convrot int8 error relative, plain %.5f, rotated %.5f  (x%.1f smaller)'
          % (relative_error(plain, weight), relative_error(unrotated, weight),
             relative_error(plain, weight) / relative_error(unrotated, weight)))


if __name__ == '__main__':
    main()
