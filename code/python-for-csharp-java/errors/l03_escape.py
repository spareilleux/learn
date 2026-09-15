# errors/l03_escape.py
import re

pattern = "^https?://.*/(api|v\d+)/"  # \d is not an escape sequence of a Python string
print(pattern)
print(bool(re.match(pattern, "https://example.com/v2/chords")))

text = "C:\new\tabs"  # \n and \t are escape sequences: a newline and a tab
print(text)
