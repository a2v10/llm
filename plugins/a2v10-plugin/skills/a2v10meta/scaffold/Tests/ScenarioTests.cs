// Copyright © 2026 Oleksandr Kukhtin. All rights reserved.

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

using A2v10.Metadata;

using Xunit;

namespace Tests;

/* One file - one scenario - one line in the test list, named by its path under scenarios/ without
 * the extension. Steps are not test cases: each stands on the one before it, so the first that
 * fails is reported inside the message.
 */
[Collection(AppCollection.Name)]
public sealed class ScenarioTests(AppFixture fixture)
{
    static readonly String Root = Path.Combine(AppContext.BaseDirectory, "scenarios");

    // a new application has no scenarios yet, and no folder either: an empty list, not a failure
    public static IEnumerable<TheoryDataRow<String>> All()
        => !Directory.Exists(Root) ? [] : Directory.EnumerateFiles(Root, "*.json", SearchOption.AllDirectories)
            .Select(f => Path.ChangeExtension(Path.GetRelativePath(Root, f), null).Replace('\\', '/'))
            .Order(StringComparer.Ordinal)
            .Select(name => new TheoryDataRow<String>(name) { TestDisplayName = name });

    [Theory(SkipTestWithoutData = true)]
    [MemberData(nameof(All))]
    public async Task Scenario(String name)
    {
        try
        {
            await fixture.RunScenarioAsync(Path.Combine(Root, name + ".json"));
        }
        catch (ScenarioException ex)
        {
            Assert.Fail(ex.Message);
        }
    }
}
