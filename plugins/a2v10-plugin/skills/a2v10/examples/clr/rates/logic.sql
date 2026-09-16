-- Currency rates: list for the page, merge for the clr handler
------------------------------------------------
create or alter procedure cat.[CurrencyRate.Index]
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Rates!TRate!Array] = null,
		[Id!!Id] = r.Id, r.[Code], r.[Name], r.[Date], r.[Rate]
	from cat.[CurrencyRates] r
	order by r.[Date] desc, r.[Code];
end
go
------------------------------------------------
drop procedure if exists cat.[CurrencyRate.Merge];
drop type if exists cat.[CurrencyRate.TableType];
go
------------------------------------------------
create type cat.[CurrencyRate.TableType]
as table(
	[Code] nvarchar(8),
	[Name] nvarchar(255),
	[Date] date,
	[Rate] money
);
go
------------------------------------------------
-- Called from RatesHandler, by this explicit name — a clr command derives nothing.
create or alter procedure cat.[CurrencyRate.Merge]
@UserId bigint = null,
@Rates cat.[CurrencyRate.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	merge cat.[CurrencyRates] as t
	using @Rates as s
	on t.[Code] = s.[Code] and t.[Date] = s.[Date]
	when matched then update set
		t.[Name] = s.[Name],
		t.[Rate] = s.[Rate]
	when not matched by target then insert
		([Code], [Name], [Date], [Rate]) values
		(s.[Code], s.[Name], s.[Date], s.[Rate]);
end
go
