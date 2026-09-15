# examples/l03_grid.py
# A fretboard of 3 strings and 4 frets, where 1 marks a finger
shared = [[0] * 4] * 3  # the outer * copies the reference to one inner list three times
shared[0][2] = 1
print(shared)

grid = [[0] * 4 for _ in range(3)]  # the comprehension builds a new inner list each time
grid[0][2] = 1
print(grid)
print(shared[0] is shared[1], grid[0] is grid[1])
