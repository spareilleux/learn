using System.Numerics;
using System.Reflection;
using System.Runtime.CompilerServices;
using GA.Core.Abstractions;
using GA.Core.Collections.Abstractions;
using GA.Core.ValueObjects;
using GA.Domain.Core.Instruments.Primitives;
using GA.Domain.Core.Theory.Atonal;
using static Advanced.Report;

namespace Advanced;

// Lesson 5: reified generics, constraints, default(T), static abstract members and generic math, variance,
// allows ref struct, per-type static caches, and how the JIT shares generic code
public static class Lesson5
{
    public static void Run()
    {
        Reified();
        Constraints();
        Defaults();
        StaticAbstract();
        GenericMath();
        Variance();
        RefStructs();
        StaticCaches();
        GaValueObjectList();
        Exercises();
    }

    // ---------------------------------------------------------------- reified generics

    static void Reified()
    {
        Title("Reified generics: every instantiation is a type of its own");
        Line($"typeof(List<int>) == typeof(List<string>): {typeof(List<int>) == typeof(List<string>)}");
        Line($"typeof(List<PitchClass>): {typeof(List<PitchClass>)}");
        Line($"new List<PitchClass>() is List<int>: {(object)new List<PitchClass>() is List<int>}");
        Line($"NameOf<PitchClass>(): {NameOf<PitchClass>()}; new T[3] is {NewArray<PitchClass>(3).GetType()}");
        Line($"12 pitch classes in a List<PitchClass>: {Allocated(() => ListOfValues(12))} bytes");
        Line($"12 pitch classes in a List<object>:     {Allocated(() => ListOfObjects(12))} bytes");
    }

    static string NameOf<T>() => typeof(T).Name;

    static T[] NewArray<T>(int length) => new T[length];

    [MethodImpl(MethodImplOptions.NoInlining)]
    static List<PitchClass> ListOfValues(int count)
    {
        var list = new List<PitchClass>(count);
        for (var i = 0; i < count; i++) list.Add(PitchClass.FromValue(i));
        return list;
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    static List<object> ListOfObjects(int count)
    {
        var list = new List<object>(count);
        for (var i = 0; i < count; i++) list.Add(PitchClass.FromValue(i));
        return list;
    }

    // ---------------------------------------------------------------- constraints

    static void Class<T>() where T : class { }
    static void Struct<T>() where T : struct { }
    static void Unmanaged<T>() where T : unmanaged { }
    static void NotNull<T>() where T : notnull { }
    static void New<T>() where T : new() { }
    static void Enum<T>() where T : struct, System.Enum { }
    static void AllowsRefStruct<T>() where T : allows ref struct { }

    static void Constraints()
    {
        Title("Constraints in the metadata: what the runtime sees");
        foreach (var name in new[] { "Class", "Struct", "Unmanaged", "NotNull", "New", "Enum", "AllowsRefStruct" })
        {
            var parameter = typeof(Lesson5).GetMethod(name, BindingFlags.NonPublic | BindingFlags.Static)!.GetGenericArguments()[0];
            var types = parameter.GetGenericParameterConstraints().Select(t => t.Name).ToList();
            var attributes = parameter.GetCustomAttributesData().Select(a => a.AttributeType.Name).ToList();
            Line($"{name,-16} {parameter.GenericParameterAttributes}; types [{string.Join(", ", types)}]; attributes [{string.Join(", ", attributes)}]");
        }

        Title("Constraints the compiler checks and the runtime doesn't");
        Line($"MakeGenericMethod((int, string)) on 'where T : unmanaged': {TryMake("Unmanaged", typeof((int, string)))}");
        Line($"MakeGenericMethod(string) on 'where T : unmanaged':        {TryMake("Unmanaged", typeof(string))}");
        Line($"MakeGenericMethod(int?) on 'where T : struct':            {TryMake("Struct", typeof(int?))}");
        Line($"sizeof(T) with T : unmanaged: PitchClass {SizeOf<PitchClass>()}, (byte, long) {SizeOf<(byte, long)>()}");
        Line($"IsReferenceOrContainsReferences: PitchClass {RuntimeHelpers.IsReferenceOrContainsReferences<PitchClass>()}, (int, string) {RuntimeHelpers.IsReferenceOrContainsReferences<(int, string)>()}");
        Line($"new T() with T : new(): {Create<System.Text.StringBuilder>().GetType().Name}, Str {Create<Str>().Value}");
    }

    static string TryMake(string method, Type argument)
    {
        try
        {
            typeof(Lesson5).GetMethod(method, BindingFlags.NonPublic | BindingFlags.Static)!.MakeGenericMethod(argument);
            return "accepted";
        }
        catch (ArgumentException e)
        {
            return $"{e.GetType().Name}";
        }
    }

    static unsafe int SizeOf<T>() where T : unmanaged => sizeof(T);

    public static T Create<T>() where T : new() => new T();

    // ---------------------------------------------------------------- default(T) and T?

    static T? FirstOrDefault<T>(IEnumerable<T> items, Func<T, bool> predicate)
    {
        foreach (var item in items)
        {
            if (predicate(item)) return item;
        }
        return default;
    }

    static T? FirstOrNull<T>(IEnumerable<T> items, Func<T, bool> predicate) where T : struct
    {
        foreach (var item in items)
        {
            if (predicate(item)) return item;
        }
        return null;
    }

    static void Defaults()
    {
        Title("default(T), and what T? means");
        Line($"FirstOrDefault(1 2 3, > 5): {FirstOrDefault<int>([1, 2, 3], x => x > 5)}");
        Line($"FirstOrDefault(\"C\" \"G\", empty): {FirstOrDefault<string>(["C", "G"], s => s.Length == 0) ?? "null"}");
        Line($"FirstOrNull(1 2 3, > 5): {FirstOrNull<int>([1, 2, 3], x => x > 5)?.ToString() ?? "null"}");
        Line($"return type of FirstOrDefault<int>: {ReturnType("FirstOrDefault")}; of FirstOrNull<int>: {ReturnType("FirstOrNull")}");
        Line($"default(PitchClass): {default(PitchClass)}, the pitch class C");
        Line($"default(Str).Value: {default(Str).Value}; Str.FromValue(0): {Try(() => Str.FromValue(0))}");
        Line($"new Str[6]: {string.Join(" ", new Str[6].Select(s => s.Value))}");
    }

    static string ReturnType(string method) =>
        typeof(Lesson5).GetMethod(method, BindingFlags.NonPublic | BindingFlags.Static)!.MakeGenericMethod(typeof(int)).ReturnType.Name;

    static string Try<T>(Func<T> func)
    {
        try
        {
            return $"{func()}";
        }
        catch (Exception e)
        {
            return e.GetType().Name;
        }
    }

    // ---------------------------------------------------------------- static abstract members

    static string Range<T>() where T : IRangeValueObject<T> =>
        $"{typeof(T).Name,-13} {T.Min,2} to {T.Max,-2}  {T.Max.Value - T.Min.Value + 1,2} values";

    static IEnumerable<T> AllOf<T>() where T : IRangeValueObject<T> =>
        Enumerable.Range(T.Min.Value, T.Max.Value - T.Min.Value + 1).Select(v => T.FromValue(v));

    static int CountItems<T>() where T : IStaticReadonlyCollection<T> => T.Items.Count;

    static void StaticAbstract()
    {
        Title("Static abstract members: GA's IRangeValueObject<TSelf>");
        Line(Range<PitchClass>());
        Line(Range<IntervalClass>());
        Line(Range<Fret>());
        Line(Range<Str>());
        Line($"AllOf<IntervalClass>(): {string.Join(" ", AllOf<IntervalClass>())}");
        Line($"CountItems<PitchClass>() through IStaticReadonlyCollection<T>.Items: {CountItems<PitchClass>()}");
    }

    // ---------------------------------------------------------------- generic math

    public static T Sum<T>(ReadOnlySpan<T> values) where T : INumberBase<T>
    {
        var sum = T.Zero;
        foreach (var value in values) sum += value;
        return sum;
    }

    static T Mean<T>(ReadOnlySpan<T> values) where T : INumber<T> => Sum(values) / T.CreateChecked(values.Length);

    static T AddChecked<T>(T left, T right) where T : IAdditionOperators<T, T, T> => checked(left + right);

    static T AddUnchecked<T>(T left, T right) where T : IAdditionOperators<T, T, T> => unchecked(left + right);

    static void GenericMath()
    {
        Title("Generic math: one Sum and one Mean for every number type");
        Line($"int     sum {Sum<int>([1, 2, 3, 4])}, mean {Mean<int>([1, 2, 3, 4])}");
        Line($"double  sum {Sum<double>([1, 2, 3, 4])}, mean {Mean<double>([1, 2, 3, 4])}");
        Line($"decimal sum {Sum<decimal>([0.1m, 0.2m])}, double sum {Sum<double>([0.1, 0.2])}");
        Line($"byte    250 + 10: unchecked {AddUnchecked<byte>(250, 10)}, checked {Try(() => AddChecked<byte>(250, 10))}");
        Line($"int     MaxValue + 1: unchecked {AddUnchecked(int.MaxValue, 1)}, checked {Try(() => AddChecked(int.MaxValue, 1))}");
        Line($"double  MaxValue + MaxValue: checked {AddChecked(double.MaxValue, double.MaxValue)}");
        Line($"byte.CreateChecked(300) {Try(() => byte.CreateChecked(300))}, CreateSaturating {byte.CreateSaturating(300)}, CreateTruncating {byte.CreateTruncating(300)}");
        Line($"int.CreateSaturating(double.NaN) {int.CreateSaturating(double.NaN)}, int.CreateSaturating(1e10) {int.CreateSaturating(1e10)}");
    }

    // ---------------------------------------------------------------- variance

    static void Variance()
    {
        Title("Variance: in, out, and why List<T> has neither");
        IEnumerable<string> names = ["C", "G"];
        IEnumerable<object> objects = names;
        Line($"IEnumerable<string> as IEnumerable<object>: {ReferenceEquals(objects, names)}");
        Line($"List<string> is IEnumerable<object>: {(object)new List<string>() is IEnumerable<object>}; is IList<object>: {(object)new List<string>() is IList<object>}");
        Line($"List<int> is IEnumerable<object>: {(object)new List<int>() is IEnumerable<object>}");
        Action<object> printAny = _ => { };
        Action<string> printString = printAny;
        Line($"Action<object> as Action<string>: {ReferenceEquals(printAny, printString)}");
        object[] array = new string[1];
        Line($"object[] array = new string[1]; array[0] = PitchClass.C: {TryAction(() => array[0] = PitchClass.C)}");
        foreach (var type in new[] { typeof(IEnumerable<>), typeof(IReadOnlyList<>), typeof(IList<>), typeof(Action<>), typeof(Func<,>), typeof(IComparer<>), typeof(IStaticReadonlyCollection<>) })
        {
            var variance = type.GetGenericArguments().Select(a => (a.GenericParameterAttributes & GenericParameterAttributes.VarianceMask).ToString());
            Line($"  {type.Name,-30} {string.Join(", ", variance)}");
        }
        Line($"GA ModalFamily (class) is IStaticReadonlyCollection<object>: {typeof(IStaticReadonlyCollection<object>).IsAssignableFrom(typeof(ModalFamily))}");
        Line($"GA PitchClass (struct) is IStaticReadonlyCollection<object>: {typeof(IStaticReadonlyCollection<object>).IsAssignableFrom(typeof(PitchClass))}");
    }

    static string TryAction(Action action)
    {
        try
        {
            action();
            return "ok";
        }
        catch (Exception e)
        {
            return e.GetType().Name;
        }
    }

    // ---------------------------------------------------------------- allows ref struct

    static TResult Apply<T, TResult>(T value, Func<T, TResult> func) where T : allows ref struct => func(value);

    static void RefStructs()
    {
        Title("allows ref struct: which generic parameters accept a Span<T>");
        foreach (var type in new[] { typeof(Func<,>), typeof(Action<>), typeof(IEquatable<>), typeof(IComparable<>), typeof(IEnumerable<>), typeof(IEqualityComparer<>), typeof(List<>), typeof(Dictionary<,>), typeof(Span<>), typeof(Nullable<>) })
        {
            var allows = type.GetGenericArguments().Select(a => a.GenericParameterAttributes.HasFlag(GenericParameterAttributes.AllowByRefLike) ? "yes" : "no");
            Line($"  {type.Name,-20} {string.Join(", ", allows)}");
        }
        Line($"Apply(\"x 3 2 0 1 0\".AsSpan(), span => span.Count(' ')): {Apply("x 3 2 0 1 0".AsSpan(), span => span.Count(' '))}");
    }

    // ---------------------------------------------------------------- per-type static caches

    static int s_initializations;

    public static class TypeCache<T>
    {
        public static readonly int Id;
        public static int Hits;

        // An explicit static constructor: the type is initialized at its first use, not earlier
        static TypeCache()
        {
            Id = ++s_initializations;
            Line($"  TypeCache<{typeof(T).Name}> initialized");
        }
    }

    static int Hit<T>() => ++TypeCache<T>.Hits;

    static void StaticCaches()
    {
        Title("A static field per closed type: a cache the runtime keys by T");
        Hit<string>(); Hit<object>(); Hit<int>(); Hit<string>(); Hit<string>();
        Line($"Id: string {TypeCache<string>.Id}, object {TypeCache<object>.Id}, int {TypeCache<int>.Id}; initializations {s_initializations}");
        Line($"Hits: string {TypeCache<string>.Hits}, object {TypeCache<object>.Hits}, int {TypeCache<int>.Hits}");
        Line($"EqualityComparer<T>.Default: int {EqualityComparer<int>.Default.GetType().Name}, string {EqualityComparer<string>.Default.GetType().Name}, PitchClass {EqualityComparer<PitchClass>.Default.GetType().Name}");
        Line($"                             int? {EqualityComparer<int?>.Default.GetType().Name}, object {EqualityComparer<object>.Default.GetType().Name}, DayOfWeek {EqualityComparer<DayOfWeek>.Default.GetType().Name}");
        Line($"the same instance each time: {ReferenceEquals(EqualityComparer<PitchClass>.Default, EqualityComparer<PitchClass>.Default)}");
    }

    // ---------------------------------------------------------------- how the JIT shares generic code

    public static class Shared<T>
    {
        public static int Calls;

        [MethodImpl(MethodImplOptions.NoInlining)]
        public static string Describe(T value)
        {
            Calls++;
            return typeof(T).Name;
        }
    }

    // Run with DOTNET_JitStdOutFile and DOTNET_JitDisasmSummary=1: check.sh lists the Describe methods the JIT compiled
    public static void JitSharing()
    {
        Title("How the JIT shares generic code: one Describe per value type, one for all reference types");
        ReportShared<int>(42);
        ReportShared<long>(42L);
        ReportShared<PitchClass>(PitchClass.C);
        ReportShared<string>("C");
        ReportShared<object>(new object());
        ReportShared<List<int>>([]);
        Line($"ReadStatic<int>(10) {ReadStatic<int>(10)}, ReadStatic<string>(10) {ReadStatic<string>(10)}");
    }

    static void ReportShared<T>(T value)
    {
        var before = System.Runtime.JitInfo.GetCompiledMethodCount(currentThread: true);
        var name = Shared<T>.Describe(value);
        var compiled = System.Runtime.JitInfo.GetCompiledMethodCount(currentThread: true) - before;
        Line($"Shared<{name}>.Describe: Calls {Shared<T>.Calls}");
        Machine($"Shared<{name}>.Describe: {compiled} methods compiled on this thread by the first call");
    }

    // Run with DOTNET_JitDisasm=ReadStatic to see the code of both instantiations at every tier
    public static void JitTiers()
    {
        var sum = 0;
        for (var round = 0; round < 50; round++)
        {
            for (var call = 0; call < 100; call++) sum += ReadStatic<int>(1000) + ReadStatic<string>(1000);
            Thread.Sleep(10);
        }
        Line($"ReadStatic<int> and ReadStatic<string>, 5,000 calls each: {sum}");
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    public static int ReadStatic<T>(int times)
    {
        var sum = 0;
        for (var i = 0; i < times; i++) sum += Counter<T>.Value;
        return sum;
    }

    public static class Counter<T>
    {
        public static int Value = 1;
    }

    // ---------------------------------------------------------------- GA

    static void GaValueObjectList()
    {
        Title("GA: what IStaticValueObjectList<TSelf> costs per access");
        Line($"PitchClass.Items:                        {Allocated(() => _ = PitchClass.Items)} bytes, the same object twice: {ReferenceEquals(PitchClass.Items, PitchClass.Items)}");
        Line($"foreach over PitchClass.Items:           {Allocated(() => SumItems())} bytes");
        Line($"PitchClass.Values[3]:                    {Allocated(() => _ = PitchClass.Values[3])} bytes, Values is {PitchClass.Values.GetType().Name}");
        Line($"ValueObjectUtils<PitchClass>.Values[3]:  {Allocated(() => _ = ValueObjectUtils<PitchClass>.Values[3])} bytes");
        Line($"PitchClass.ItemsSpan[3]:                 {Allocated(() => _ = PitchClass.ItemsSpan[3])} bytes");
        Line($"SumAll<PitchClass>() over ItemsSpan:     {SumAll<PitchClass>()}, {Allocated(() => SumAll<PitchClass>())} bytes");

        var before = GC.GetAllocatedBytesForCurrentThread();
        var strings = ValueObjectUtils<Str>.ItemsSpan.Length;
        Machine($"first access to ValueObjectUtils<Str>.ItemsSpan ({strings} items) allocated {GC.GetAllocatedBytesForCurrentThread() - before} bytes");

        Title("GA: who implements IStaticReadonlyCollection<TSelf>");
        var implementers = new[] { typeof(PitchClass).Assembly, typeof(IValueObject).Assembly }
            .SelectMany(LoadableTypes)
            .Where(t => !t.IsInterface && t.GetInterfaces().Any(i => i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IStaticReadonlyCollection<>)))
            .ToList();
        Line($"{implementers.Count(t => t.IsValueType)} structs, {implementers.Count(t => !t.IsValueType)} classes: {string.Join(", ", implementers.Where(t => !t.IsValueType).Select(t => t.Name).Order(StringComparer.Ordinal))}");

        Title("GA: the two range checks with normalize: true");
        foreach (var value in new[] { -1, 12, 13 })
        {
            Line($"{value,3}: IRangeValueObject<PitchClass>.EnsureValueInRange {IRangeValueObject<PitchClass>.EnsureValueInRange(value, 0, 11, normalize: true),2}, ValueObjectUtils<PitchClass>.EnsureValueRange {ValueObjectUtils<PitchClass>.EnsureValueRange(value, 0, 11, normalize: true),2}");
        }
    }

    static IEnumerable<Type> LoadableTypes(Assembly assembly)
    {
        try
        {
            return assembly.GetTypes();
        }
        catch (ReflectionTypeLoadException e)
        {
            return e.Types.OfType<Type>();
        }
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    static int SumItems()
    {
        var sum = 0;
        foreach (var pitchClass in PitchClass.Items) sum += pitchClass.Value;
        return sum;
    }

    // Generic over any GA range value object, through the cached span: no interface call, no allocation
    public static int SumAll<T>() where T : IRangeValueObject<T>
    {
        var sum = 0;
        foreach (var item in ValueObjectUtils<T>.ItemsSpan) sum += item.Value;
        return sum;
    }

    // ---------------------------------------------------------------- exercises

    // Exercise 1: a modulo that never returns a negative number, for any number type
    public static T Wrap<T>(T value, T size) where T : INumber<T>
    {
        var remainder = value % size;
        return remainder < T.Zero ? remainder + size : remainder;
    }

    // Exercise 2: parse a space-separated list with any IParsable<T>
    public static List<T> ParseAll<T>(string text) where T : IParsable<T> =>
        [.. text.Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(s => T.Parse(s, null))];

    static void Exercises()
    {
        Title("Exercise solutions");
        Line($"1. Wrap(-1, 12) {Wrap(-1, 12)}, Wrap(-13L, 12L) {Wrap(-13L, 12L)}, Wrap(-0.5, 12.0) {Wrap(-0.5, 12.0)}, Wrap(25, 12) {Wrap(25, 12)}");
        Line($"2. ParseAll<PitchClass>(\"0 4 7 T\") [{string.Join(" ", ParseAll<PitchClass>("0 4 7 T"))}], ParseAll<int>(\"0 4 7 10\") sum {ParseAll<int>("0 4 7 10").Sum()}");
    }
}
