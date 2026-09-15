# examples/l04_defaults.py
def add_note(note: str, chord: list[str] = []) -> list[str]:
    chord.append(note)  # the default list was created once, when def ran, and every call shares it
    return chord


print(add_note("C"))
print(add_note("E"))
print(add_note("G", ["G"]))
print(add_note("B"))
print(add_note.__defaults__)


# A default is an expression evaluated once, when def runs, like any other statement
calls = 0


def next_id() -> int:
    global calls
    calls += 1
    return calls


def log(message: str, entry_id: int = next_id()) -> str:
    return f"#{entry_id} {message}"


print(log("first"), log("second"), "next_id was called", calls, "time")

# Arguments are evaluated before the call, even the default of dict.get that isn't needed
entry = {"id": "methylation-42"}
print(entry.get("id", f"generated-{next_id()}"), "next_id was called", calls, "times")
