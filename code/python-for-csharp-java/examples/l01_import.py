# examples/l01_import.py
import l01_greeting
import l01_greeting  # a second import finds the module in sys.modules and runs nothing

print(l01_greeting.greet("importer"))
