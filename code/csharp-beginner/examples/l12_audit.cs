#:package Newtonsoft.Json@12.0.1
using Newtonsoft.Json;

// An old version of a popular package: the restore warns that it has a known vulnerability
Console.WriteLine(JsonConvert.SerializeObject(new { Chord = "Am7", Frets = "x02010" }));
