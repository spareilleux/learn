// compare_fail/l04_variance_annotation.cs
Console.WriteLine(typeof(IMislabeled<>).Name);

interface IMislabeled<out T>
{
    void Accept(T value);
}
