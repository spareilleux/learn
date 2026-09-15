# errors/l03_changed_size.py
stock = {"capo": 2, "strings": 0, "picks": 50, "tuner": 0}

print({name: count for name, count in stock.items() if count > 0})  # build a new dict instead

for name, count in stock.items():
    if count == 0:
        del stock[name]
