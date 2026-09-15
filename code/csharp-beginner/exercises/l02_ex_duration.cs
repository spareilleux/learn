// Exercise 1: a song of 3725 seconds, in hours, minutes and seconds
int total = 3725;
int hours = total / 3600;
int minutes = total % 3600 / 60;
int seconds = total % 60;
Console.WriteLine($"{hours} h {minutes:D2} min {seconds:D2} s");
