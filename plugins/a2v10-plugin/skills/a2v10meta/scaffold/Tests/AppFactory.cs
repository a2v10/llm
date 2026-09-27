// Copyright © 2026 Oleksandr Kukhtin. All rights reserved.

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

using A2v10.Infrastructure;
using A2v10.Metadata;
using A2v10.Services.Api;

using Xunit;

namespace Tests;

/* The host exactly as Startup composes it - modules, report engines, whatever the application
 * registers - with three substitutions: 'Default' points at the test database, module paths are
 * absolute, and the user is DefaultAdminUser (99) instead of the one a request would set up; and
 * one addition: the test environment, which a host serving the browser does not register.
 */
public sealed class AppFactory : WebApplicationFactory<WebApp.Startup>
{
    protected override IHost CreateHost(IHostBuilder builder)
    {
        builder.ConfigureAppConfiguration((ctx, cfg) =>
        {
            var app = cfg.Build();
            var modules = ModulePaths(ctx.HostingEnvironment.ContentRootPath, app);
            var testDb = TestEnvironment.TestConnectionString(app.GetConnectionString("Default")
                ?? throw new InvalidOperationException("ConnectionStrings:Default is not set."));
            cfg.AddInMemoryCollection([
                new("ConnectionStrings:Default", testDb),
                .. modules.Select(m => new KeyValuePair<String, String?>($"Application:Modules:{m.Key}:Path", m.Value))
            ]);
        });
        builder.ConfigureServices(services => services.UseTestEnvironment()
            .AddSingleton<ICurrentUser, DefaultAdminUser>());
        return base.CreateHost(builder);
    }

    /* A module path ('../MainApp') is relative to the host's folder, and the platform resolves a
     * relative one against the current directory: the project folder for a host started the usual
     * way, bin/ for a test process. So the host makes them absolute. A clr module has no folder.
     */
    static Dictionary<String, String> ModulePaths(String contentRoot, IConfiguration app)
        => app.GetSection("Application:Modules").GetChildren()
            .Where(m => m["Assembly"] == null && m["Path"] is String p && !p.StartsWith("clr-type:"))
            .ToDictionary(m => m.Key, m => Path.GetFullPath(m["Path"]!, contentRoot));
}

/* One per run: the database is recreated once, and scenarios keep out of each other's way by
 * their own records, not by a database each.
 */
public sealed class AppFixture : IAsyncLifetime
{
    public AppFactory App { get; } = new();

    public async ValueTask InitializeAsync()
    {
        using var scope = App.Services.CreateScope();
        var sp = scope.ServiceProvider;
        // full.sql is where the host's sql.json writes it, made by the build of the host
        var fullSql = Path.Combine(sp.GetRequiredService<IHostEnvironment>().ContentRootPath, "_sqlscripts", "full.sql");
        await sp.GetRequiredService<TestEnvironment>().CreateTestDatabaseAsync(fullSql);
        await sp.GetRequiredService<DatabaseMetadataProvider>().DeployDatabaseAllAsync(null);
    }

    public async Task RunScenarioAsync(String file)
    {
        using var scope = App.Services.CreateScope();
        await scope.ServiceProvider.GetRequiredService<TestEnvironment>().RunScenarioAsync(file);
    }

    public ValueTask DisposeAsync() => App.DisposeAsync();
}

// a collection, not a class fixture: one per class would recreate the database per class
[CollectionDefinition(Name)]
public sealed class AppCollection : ICollectionFixture<AppFixture>
{
    public const String Name = "App";
}
