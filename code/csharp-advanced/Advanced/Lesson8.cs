using System.Reactive;
using System.Reactive.Concurrency;
using System.Reactive.Disposables;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using Microsoft.Reactive.Testing;
using static Advanced.Lesson6;
using static Advanced.Report;

namespace Advanced;

// Lesson 8: Rx.NET: IObservable<T>, cold and hot sources, operators in virtual time, schedulers, the missing
// backpressure, asynchronous steps and order, errors and retries, and GA's reactive demo
public static class Lesson8
{
    public static void Run() => RunAsync().GetAwaiter().GetResult();

    static async Task RunAsync()
    {
        Types();
        ColdAndHot();
        VirtualTime();
        await Schedulers();
        await NoBackpressure();
        await AsyncSteps();
        await GaReactiveDemo();
        await Errors();
        await Exercises();
    }

    static readonly string[] Progression = ["Dm7", "G7", "Cmaj7", "A7"];

    static void Types()
    {
        Title("Where the types come from");
        Line($"IObservable<T>: {typeof(IObservable<>).Assembly.GetName().Name}; Observable: {typeof(Observable).Assembly.GetName().Name} {typeof(Observable).Assembly.GetName().Version}");
    }

    static void ColdAndHot()
    {
        Title("Cold: each subscriber runs the source");
        var runs = 0;
        var cold = Observable.Create<string>(observer =>
        {
            runs++;
            foreach (var chord in Progression)
            {
                observer.OnNext(chord);
            }

            observer.OnCompleted();
            return Disposable.Empty;
        });
        var first = new List<string>();
        var second = new List<string>();
        cold.Subscribe(first.Add);
        cold.Subscribe(second.Add);
        Line($"source ran {runs} times; first got {string.Join(" ", first)}, second got {string.Join(" ", second)}");

        Title("Hot: a Subject pushes to whoever is subscribed now");
        var hot = new Subject<string>();
        var early = new List<string>();
        var late = new List<string>();
        hot.OnNext("Dm7");
        hot.Subscribe(early.Add);
        hot.OnNext("G7");
        hot.Subscribe(late.Add);
        hot.OnNext("Cmaj7");
        hot.OnCompleted();
        Line($"subscribed before G7: {string.Join(" ", early)}; subscribed before Cmaj7: {string.Join(" ", late)}; Dm7 went to nobody");

        var replay = new ReplaySubject<string>(bufferSize: 2);
        foreach (var chord in Progression)
        {
            replay.OnNext(chord);
        }

        var replayed = new List<string>();
        replay.Subscribe(replayed.Add);
        Line($"ReplaySubject(2), subscribed after four chords: {string.Join(" ", replayed)}");

        runs = 0;
        var shared = cold.Publish();
        var a = new List<string>();
        var b = new List<string>();
        shared.Subscribe(a.Add);
        shared.Subscribe(b.Add);
        using (shared.Connect())
        {
            Line($"Publish() and Connect(): source ran {runs} time; both got {string.Join(" ", a)} / {string.Join(" ", b)}");
        }
    }

    static long Ms(double milliseconds) => TimeSpan.FromMilliseconds(milliseconds).Ticks;

    static void VirtualTime()
    {
        Title("Virtual time: notes played within 50 ms of each other form a chord");
        var scheduler = new TestScheduler();
        var notes = scheduler.CreateHotObservable(
            ReactiveTest.OnNext(Ms(0), "C"), ReactiveTest.OnNext(Ms(12), "E"), ReactiveTest.OnNext(Ms(25), "G"),
            ReactiveTest.OnNext(Ms(510), "D"), ReactiveTest.OnNext(Ms(540), "F"), ReactiveTest.OnNext(Ms(570), "A"),
            ReactiveTest.OnNext(Ms(1010), "B"),
            ReactiveTest.OnCompleted<string>(Ms(1200)));

        var chords = notes
            .Buffer(notes.Throttle(TimeSpan.FromMilliseconds(50), scheduler))
            .Where(chord => chord.Count > 0);
        var observer = scheduler.CreateObserver<IList<string>>();
        chords.Subscribe(observer);
        scheduler.Start();
        foreach (var message in observer.Messages)
        {
            var value = message.Value;
            Line($"t = {TimeSpan.FromTicks(message.Time).TotalMilliseconds,4} ms  {value.Kind}{(value.Kind == NotificationKind.OnNext ? " " + string.Join(" ", value.Value) : "")}");
        }

        Title("The same notes: Sample(100 ms) and Buffer(100 ms)");
        foreach (var (name, pipeline) in new (string, Func<IObservable<string>, IScheduler, IObservable<string>>)[]
        {
            ("Sample(100 ms)", (source, s) => source.Sample(TimeSpan.FromMilliseconds(100), s)),
            ("Buffer(100 ms)", (source, s) => source.Buffer(TimeSpan.FromMilliseconds(100), s).Select(buffer => $"[{string.Join(" ", buffer)}]")),
        })
        {
            var testScheduler = new TestScheduler();
            var source = testScheduler.CreateHotObservable(
                ReactiveTest.OnNext(Ms(0), "C"), ReactiveTest.OnNext(Ms(12), "E"), ReactiveTest.OnNext(Ms(25), "G"),
                ReactiveTest.OnNext(Ms(510), "D"), ReactiveTest.OnNext(Ms(540), "F"), ReactiveTest.OnNext(Ms(570), "A"),
                ReactiveTest.OnNext(Ms(1010), "B"),
                ReactiveTest.OnCompleted<string>(Ms(1200)));
            var results = testScheduler.CreateObserver<string>();
            pipeline(source, testScheduler).Subscribe(results);
            testScheduler.Start();
            var shown = results.Messages
                .Where(m => m.Value.Kind == NotificationKind.OnNext && m.Value.Value != "[]")
                .Select(m => $"{TimeSpan.FromTicks(m.Time).TotalMilliseconds}:{m.Value.Value}");
            Line($"{name}: {string.Join("  ", shown)}");
        }
    }

    static async Task Schedulers()
    {
        Title("Schedulers: Rx runs the observer on the thread that calls OnNext, unless told otherwise");
        var subject = new Subject<int>();
        var callerThread = Environment.CurrentManagedThreadId;
        int? observerThread = null;
        subject.Subscribe(_ => observerThread = Environment.CurrentManagedThreadId);
        subject.OnNext(1);
        Line($"Subject.OnNext: observer ran on the caller's thread {observerThread == callerThread}, before OnNext returned {observerThread is not null}");

        using var loop = new EventLoopScheduler(start => new Thread(start) { Name = "rx-loop", IsBackground = true });
        var observedOn = await Observable.Return(1).ObserveOn(loop).Select(_ => Thread.CurrentThread.Name);
        Line($"ObserveOn(rx-loop): observer on {observedOn}");

        var source = Observable.Create<string?>(observer =>
        {
            observer.OnNext(Thread.CurrentThread.Name);
            observer.OnCompleted();
            return Disposable.Empty;
        });
        Line($"SubscribeOn(rx-loop): the source ran on {await source.SubscribeOn(loop)}");
        Line($"Observable.Timer(1 ms): observer on a pool thread {await Observable.Timer(TimeSpan.FromMilliseconds(1)).Select(_ => Thread.CurrentThread.IsThreadPoolThread)}");
    }

    static async Task NoBackpressure()
    {
        Title("No backpressure: without a scheduler, OnNext waits for the observer");
        var subject = new Subject<int>();
        var processed = 0;
        var insideEachCall = true;
        var pushed = 0;
        subject.Subscribe(_ =>
        {
            insideEachCall &= processed == pushed;
            processed++;
        });
        for (; pushed < 1000; pushed++)
        {
            subject.OnNext(pushed);
        }

        Line($"1,000 OnNext: the observer ran inside each call {insideEachCall}, processed {processed}");

        Title("No backpressure: behind ObserveOn, OnNext returns at once and the queue grows");
        using var loop = new EventLoopScheduler(start => new Thread(start) { Name = "rx-slow", IsBackground = true });
        var gate = new ManualResetEventSlim();
        var done = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var slowProcessed = 0;
        var queued = new Subject<byte[]>();
        using var subscription = queued.ObserveOn(loop).Subscribe(_ =>
        {
            gate.Wait();
            slowProcessed++;
        }, () => done.SetResult());

        var before = GC.GetTotalMemory(forceFullCollection: true);
        for (var i = 0; i < 10_000; i++)
        {
            queued.OnNext(new byte[1024]);
        }

        queued.OnCompleted();
        var after = GC.GetTotalMemory(forceFullCollection: true);
        Line($"10,000 OnNext of 1 KB returned while the observer held the first: processed {slowProcessed}, more than 10 MB still reachable {after - before > 10_000_000}");
        Machine($"memory reachable after pushing: {(after - before) / 1_000_000.0:F1} MB more");
        gate.Set();
        await done.Task;
        Line($"after releasing the observer: processed {slowProcessed}");
    }

    static async Task AsyncSteps()
    {
        Title("An asynchronous step: SelectMany runs batches concurrently, Concat one at a time");
        foreach (var name in new[] { "SelectMany", "Select + Concat" })
        {
            var secondStarted = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
            var overlapped = false;

            async Task<string> Process(int batch)
            {
                if (batch == 0)
                {
                    // Batch 0 waits up to 200 ms for batch 1 to start
                    overlapped = await Task.WhenAny(secondStarted.Task, Task.Delay(200)) == secondStarted.Task;
                }
                else
                {
                    secondStarted.TrySetResult();
                }

                return $"batch {batch}";
            }

            var batches = Observable.Range(0, 2);
            var pipeline = name == "SelectMany"
                ? batches.SelectMany(Process)
                : batches.Select(batch => Observable.FromAsync(() => Process(batch))).Concat();
            var results = await pipeline.ToList();
            Line($"{name,-16} batch 1 started while batch 0 ran: {overlapped,-5}  results: {string.Join(", ", results)}");
        }
    }

    record MusicalEvent(string Name, int PitchClass);

    record ProcessedEvent(string Name, int PitchClass, string Status);

    // GA's ProcessBatchAsync (PerformanceOptimizationDemo/Program.cs L297-L301)
    static async Task<IEnumerable<ProcessedEvent>> ProcessBatchAsync(IList<MusicalEvent> events)
    {
        await Task.Delay(10);
        return events.Select(e => new ProcessedEvent(e.Name, e.PitchClass, "Batch processed"));
    }

    static async Task GaReactiveDemo()
    {
        Title("GA's reactive demo: 1,000 events, batches of 100, counted after SelectMany");
        // GA buffers by time (100 ms); batches by count keep this run deterministic
        var events = Enumerable.Range(0, 1000).Select(i => new MusicalEvent($"Event_{i}", i % 12)).ToObservable();
        var processedCount = 0;
        var pipeline = events
            .Buffer(100)
            .Where(batch => batch.Count > 0)
            .SelectMany(batch => ProcessBatchAsync(batch));
        await pipeline.Do(_ => Interlocked.Increment(ref processedCount)).DefaultIfEmpty();
        Line($"element type after SelectMany: {ElementName(pipeline)}; processedCount {processedCount}");

        processedCount = 0;
        await events
            .Buffer(100)
            .SelectMany(batch => ProcessBatchAsync(batch))
            .SelectMany(processed => processed)
            .Do(_ => Interlocked.Increment(ref processedCount))
            .DefaultIfEmpty();
        Line($"with a second SelectMany that flattens each batch: processedCount {processedCount}");

        Title("Disposing the subscription drops the batch still in flight");
        var release = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var completed = false;
        var received = 0;
        var twoReceived = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var lastFinished = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var subscription = Observable.Range(0, 3)
            .SelectMany(async i =>
            {
                if (i == 2)
                {
                    await release.Task;
                    lastFinished.SetResult();
                }

                return i;
            })
            .Subscribe(_ =>
            {
                if (++received == 2)
                {
                    twoReceived.SetResult();
                }
            }, () => completed = true);
        await twoReceived.Task;
        subscription.Dispose();
        release.SetResult();
        await lastFinished.Task;
        await Task.Delay(100); // time for a result that would still be delivered
        Line($"after Dispose, then the last batch finishing: received {received}, OnCompleted {completed}");
    }

    static string ElementName<T>(IObservable<T> _) => typeof(T).IsGenericType
        ? $"{typeof(T).Name[..typeof(T).Name.IndexOf('`')]}<{typeof(T).GetGenericArguments()[0].Name}>"
        : typeof(T).Name;

    static async Task Errors()
    {
        Title("Errors: OnError ends the sequence");
        var subject = new Subject<string>();
        var seen = new List<string>();
        subject.Subscribe(seen.Add, e => seen.Add($"OnError({e.Message})"), () => seen.Add("OnCompleted"));
        subject.OnNext("Dm7");
        subject.OnError(new InvalidOperationException("the MIDI device was unplugged"));
        subject.OnNext("G7");
        subject.OnCompleted();
        var lateSubscriber = new List<string>();
        subject.Subscribe(lateSubscriber.Add, e => lateSubscriber.Add($"OnError({e.Message})"));
        Line($"observer saw: {string.Join(", ", seen)}; a later subscriber sees: {string.Join(", ", lateSubscriber)}");

        Title("Retry subscribes again; Catch switches to another sequence");
        var attempts = 0;
        var flaky = Observable.Defer(() => ++attempts < 3
            ? Observable.Throw<string>(new InvalidOperationException("scale service unavailable"))
            : Observable.Return("D dorian"));
        Line($"Retry(3): {await flaky.Retry(3)} after {attempts} subscriptions");
        attempts = -10;
        Line($"Retry(2) on a source that keeps failing: {await Outcome(async () => await flaky.Retry(2))}, {attempts + 10} subscriptions");
        attempts = -10;
        Line($"Catch: {await flaky.Catch(Observable.Return("C ionian (cached)"))}");
    }

    static async Task Exercises()
    {
        Title("Exercise solutions");
        // 1. A hot source shared by two subscribers, running once, started by the first subscriber
        var runs = 0;
        var source = Observable.Defer(() =>
        {
            runs++;
            return Progression.ToObservable();
        });
        var shared = source.Publish().RefCount(2);
        var first = new List<string>();
        var second = new List<string>();
        using (shared.Subscribe(first.Add))
        using (shared.Subscribe(second.Add))
        {
            Line($"1. Publish().RefCount(2): source ran {runs} time; first {string.Join(" ", first)}, second {string.Join(" ", second)}");
        }

        // 2. The chord detector under a note every 40 ms, for 320 ms
        var scheduler = new TestScheduler();
        var notes = scheduler.CreateHotObservable(
            [.. Enumerable.Range(0, 8).Select(i => ReactiveTest.OnNext(Ms(i * 40), "CDEFGABC"[i].ToString())),
             ReactiveTest.OnCompleted<string>(Ms(1000))]);
        var observer = scheduler.CreateObserver<string>();
        notes.Buffer(notes.Throttle(TimeSpan.FromMilliseconds(50), scheduler))
            .Where(chord => chord.Count > 0)
            .Select(chord => string.Join(" ", chord))
            .Subscribe(observer);
        scheduler.Start();
        Line($"2. a note every 40 ms from 0 to 280 ms: {string.Join("  ", observer.Messages.Where(m => m.Value.Kind == NotificationKind.OnNext).Select(m => $"{TimeSpan.FromTicks(m.Time).TotalMilliseconds}:[{m.Value.Value}]"))}");

        // 3. At most 2 batches at a time, results in completion order: Select + Merge(2)
        var running = 0;
        var maxRunning = 0;
        var gate = new object();
        var results = await Observable.Range(0, 8)
            .Select(i => Observable.FromAsync(async () =>
            {
                lock (gate) maxRunning = Math.Max(maxRunning, ++running);
                await Task.Delay(20);
                lock (gate) running--;
                return i;
            }))
            .Merge(2)
            .ToList();
        Line($"3. Select + Merge(2): {results.Count} results, at most {maxRunning} running at once, all of 0..7 {results.Order().SequenceEqual(Enumerable.Range(0, 8))}");
    }
}
