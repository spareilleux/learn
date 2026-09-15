# errors/l02_scope.py
for string in ["E", "A", "D"]:
    last = string.lower()
print(string, last)  # a loop is not a scope: both names still exist

count = 0


def add_one() -> None:
    count += 1  # an assignment anywhere in the function makes count local to all of it


add_one()
