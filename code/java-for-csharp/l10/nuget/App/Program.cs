var version = typeof(Microsoft.Extensions.DependencyInjection.IServiceCollection).Assembly.GetName().Version;
System.Console.WriteLine($"Microsoft.Extensions.DependencyInjection.Abstractions loaded: {version}");
