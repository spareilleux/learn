"""What loading a pickle runs, and what weights_only=True refuses. Harmless: the "payload" only prints a line.

    python pickle_demo.py            # the pickle part, standard library only
    python pickle_demo.py --torch    # also torch.save / torch.load, with a Python that has PyTorch
"""

import io
import pickle
import re
import sys


class Payload:
    """Pickle stores how to rebuild an object; __reduce__ lets the object choose any callable and arguments."""

    def __reduce__(self):
        return (print, ("  -> this line was printed by the unpickler, while loading the data",))


def main():
    data = pickle.dumps({"weights": [0.1, 0.2], "extra": Payload()})
    print(f"pickle: {len(data)} bytes; the opcodes name a callable to run:")
    names = [part for part in (b"builtins", b"print") if part in data]
    print(f"  contains {b' and '.join(names).decode()}")
    print("pickle.loads:")
    loaded = pickle.loads(data)
    print(f"  result: {loaded}")

    if "--torch" not in sys.argv:
        return
    import torch

    buffer = io.BytesIO()
    torch.save({"weights": torch.zeros(2), "extra": Payload()}, buffer)
    print(f"torch {torch.__version__}, torch.save: {buffer.getbuffer().nbytes} bytes")
    for weights_only in (True, False):
        buffer.seek(0)
        print(f"torch.load(weights_only={weights_only}):")
        try:
            result = torch.load(buffer, weights_only=weights_only)
            print(f"  result keys: {sorted(result)}")
        except pickle.UnpicklingError as error:
            message = re.sub(r"\x1b\[[0-9;]*m", "", str(error))  # PyTorch colours part of the message
            print(f"  UnpicklingError: {message.splitlines()[0].strip()}")
            detail = next((line.strip() for line in message.splitlines() if "GLOBAL" in line), "")
            if detail:
                print(f"  {detail}")


if __name__ == "__main__":
    main()
