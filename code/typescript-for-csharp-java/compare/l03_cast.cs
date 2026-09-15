// compare/l03_cast.cs
object parsed = "not a camera";
try { var camera = (CameraState)parsed; Console.WriteLine(camera); }
catch (InvalidCastException e) { Console.WriteLine($"(CameraState)parsed: {e.GetType().Name}"); }
Console.WriteLine($"parsed as CameraState: {(parsed as CameraState) is null}");
Console.WriteLine($"parsed is CameraState: {parsed is CameraState}");

record CameraState(double Px, double Py, double Pz);
