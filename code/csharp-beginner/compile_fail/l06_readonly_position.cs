List<Position> shape = [new Position(6, 3)];
shape[0].Fret += 2;
Position p = shape[0];
p.Fret = 5;

readonly record struct Position(int StringNumber, int Fret);
