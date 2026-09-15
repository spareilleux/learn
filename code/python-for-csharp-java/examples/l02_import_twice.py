# examples/l02_import_twice.py
import sys

import l02_config

print("imported, STRINGS =", l02_config.STRINGS)
import l02_config  # already in sys.modules: nothing runs

print("in sys.modules:", "l02_config" in sys.modules)
