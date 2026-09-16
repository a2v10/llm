// Currency rates: the clr command declared as "load" in model.json.
// Fetches the official NBU rates and writes them in ONE call.

using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

using Microsoft.Extensions.DependencyInjection;

using A2v10.Data.Interfaces;
using A2v10.Infrastructure;

// The namespace is what this file declares — the folder does not shape it.
// It is the first half of clrType: clr-type:MainApp.RatesHandler;assembly=MainApp
namespace MainApp;

public class RatesHandler(IServiceProvider serviceProvider) : IClrInvokeTarget
{
	// A public API with no key: whoever clones this example can run it as it stands.
	private const String NbuUrl = "https://bank.gov.ua/NBUStatService/v1/statdirectory/exchangenew?json";

	// The constructor takes a single IServiceProvider and the platform looks up exactly that
	// signature. Every service comes out of it.
	private readonly IDbContext _dbContext = serviceProvider.GetRequiredService<IDbContext>();
	private readonly ICurrentUser _currentUser = serviceProvider.GetRequiredService<ICurrentUser>();
	private readonly IHttpClientFactory _httpClientFactory = serviceProvider.GetRequiredService<IHttpClientFactory>();

	public async Task<Object> InvokeAsync(ExpandoObject args)
	{
		// Outbound HTTP goes through the factory, never through a new HttpClient().
		using var client = _httpClientFactory.CreateClient();
		var json = await client.GetStringAsync(NbuUrl);

		var rates = JsonSerializer.Deserialize<List<NbuRate>>(json)
			?? throw new InvalidOperationException("UI:Не вдалося прочитати відповідь НБУ");

		var rows = rates.Select(r => new CurrencyRateRow()
		{
			Code = r.Code,
			Name = r.Name,
			Date = DateTime.ParseExact(r.ExchangeDate, "dd.MM.yyyy", CultureInfo.InvariantCulture),
			Rate = r.Rate
		}).ToList();

		var prms = new ExpandoObject()
		{
			{ "UserId", _currentUser.Identity.Id }
		};

		// The whole collection in one call, against an explicitly named procedure.
		// A loop of single calls would also work — and nothing would tell you it was wrong.
		await _dbContext.SaveListAsync(null, "cat.[CurrencyRate.Merge]", prms, rows);

		// Any object; it is serialized to JSON and becomes the caller's result.
		return new { Count = rows.Count };
	}

	// What the API returns. Its names are its own — they are mapped over below,
	// not carried into the database.
	private sealed class NbuRate
	{
		[JsonPropertyName("cc")]
		public String Code { get; set; } = String.Empty;
		[JsonPropertyName("txt")]
		public String Name { get; set; } = String.Empty;
		[JsonPropertyName("rate")]
		public Decimal Rate { get; set; }
		[JsonPropertyName("exchangedate")]
		public String ExchangeDate { get; set; } = String.Empty;
	}

	// What goes to SQL. These property names are the TVP column names of
	// cat.[CurrencyRate.TableType] — they must agree, nothing checks it.
	private sealed class CurrencyRateRow
	{
		public String Code { get; set; } = String.Empty;
		public String Name { get; set; } = String.Empty;
		public DateTime Date { get; set; }
		public Decimal Rate { get; set; }
	}
}
