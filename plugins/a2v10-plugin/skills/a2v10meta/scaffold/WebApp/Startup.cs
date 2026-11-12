// Copyright © 2024-2026 Oleksandr Kukhtin. All rights reserved.

using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

using A2v10.Metadata;
using A2v10.ReportEngine.Pdf;
using A2v10.BlobStorage.FileSystem;

namespace WebApp;

public class Startup(IConfiguration configuration)
{
    public IConfiguration Configuration { get; } = configuration;

    public void ConfigureServices(IServiceCollection services)
    {
        services.UseAppMetadata()
            .UseAppMetadataXaml();

        services.UsePlatform(Configuration);

        // /mcp for the user's model: the entities of MainApp/mcp.json, the text of MainApp/mcp-instructions.txt
        services.UseMcp(Configuration, mcp => mcp
            .AddProvider<MetadataMcpToolProvider>()
            .Instructions<MetadataMcpInstructions>());

        services.AddReportEngines(factory =>
        {
            factory.RegisterEngine<PdfReportEngine>("pdf");
        });

        services.AddBlobStorages(factory =>
        {
            factory.RegisterStorage<FileSystemBlobStorage>("FileSystem");
        });
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        app.ConfigurePlatform(env, Configuration);
    }
}
