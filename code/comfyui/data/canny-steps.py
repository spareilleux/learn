"""Where Kornia's Canny stops agreeing from one machine to the next.

Lesson 6 measured that four machines give four pixel hashes for the same `Canny`
node, on the CPU, with no model. This prints a hash for each step of the filter,
on a pattern built from integers so that the input itself is identical everywhere,
so the step where the machines part company can be read off the CI logs.

The steps are Kornia's own public functions, in the order `kornia.filters.canny`
applies them, with its default kernel and sigma. Printed as information, never
compared: these hashes are expected to differ.
"""
import hashlib

import numpy as np
import torch
from kornia.filters import canny, gaussian_blur2d, spatial_gradient

WIDTH, HEIGHT = 64, 48


def pattern():
    """The same bytes on every machine: integer arithmetic, then an exact division."""
    y, x = np.mgrid[0:HEIGHT, 0:WIDTH]
    cells = ((x * 5 + y * 3) % 32 < 16) ^ ((x * 3 - y * 5) % 48 < 24)
    disc = ((x - 32) ** 2 + (y - 24) ** 2) < 12 ** 2
    grey = np.where(cells ^ disc, 224, 32).astype(np.uint8)
    return torch.from_numpy(grey).float().div(255.0)[None, None]


def digest(tensor):
    return hashlib.sha256(tensor.detach().contiguous().float().numpy().tobytes()).hexdigest()[:16]


def main():
    torch.use_deterministic_algorithms(True, warn_only=True)
    image = pattern()
    print('info canny input        %s  %s, torch %s, numpy %s'
          % (digest(image), tuple(image.shape), torch.__version__, np.__version__))

    blurred = gaussian_blur2d(image, (5, 5), (1.0, 1.0))
    print('info canny blur         %s' % digest(blurred))

    gradients = spatial_gradient(blurred, normalized=False)
    print('info canny gradient     %s' % digest(gradients))

    gx, gy = gradients[:, :, 0], gradients[:, :, 1]
    magnitude = torch.sqrt(gx * gx + gy * gy)
    print('info canny magnitude    %s  sum %.6f' % (digest(magnitude), float(magnitude.sum())))

    angle = torch.atan2(gy, gx)
    print('info canny angle        %s' % digest(angle))

    _, thin = canny(image, 0.05, 0.15, hysteresis=False)
    print('info canny thin         %s  %d edge pixels' % (digest(thin), int((thin > 0.5).sum())))

    magnitudes, edges = canny(image, 0.05, 0.15)
    print('info canny magnitudes   %s' % digest(magnitudes))
    print('info canny edges        %s  %d edge pixels of %d'
          % (digest(edges), int((edges > 0.5).sum()), WIDTH * HEIGHT))


if __name__ == '__main__':
    main()
