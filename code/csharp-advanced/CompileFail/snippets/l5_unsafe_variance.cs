// expect: CS1961
public interface IProducer<out T>
{
    T Next();

    void Accept(T item);
}
