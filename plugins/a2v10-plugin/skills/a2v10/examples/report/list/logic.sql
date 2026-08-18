-- Report.Document.List
------------------------------------------------
create or alter procedure rep.[Report.Document.List.Load]
@UserId bigint,
@Id nvarchar(64) = null, /* menu id */
@From date = null,
@To date = null,
@Agent bigint = null,
@Run bit = 0
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	set @From = isnull(@From, datefromparts(year(getdate()), month(getdate()), 1));
	set @To   = isnull(@To,   eomonth(getdate()));
	declare @end date = dateadd(day, 1, @To);

	-- # (not @): a period of documents can be large
	create table #docs (
		Id bigint, [Date] date, [No] nvarchar(32), [Sum] money,
		Agent bigint, Operation nvarchar(20));

	insert into #docs (Id, [Date], [No], [Sum], Agent, Operation)
	select d.Id, d.[Date], d.[No], d.[Sum], d.Agent, d.Operation
	from doc.Documents d
	where d.Void = 0
		and d.[Date] >= @From and d.[Date] < @end
		and (@Agent is null or d.Agent = @Agent);

	select [RepData!TRepData!Array] = null, [Id!!Id] = d.Id,
		d.[Date], d.[No], d.[Sum],
		[Agent!TAgent!RefId] = d.Agent,
		[Operation!TOperation!RefId] = d.Operation
	from #docs d
	order by d.[Date], d.Id;

	-- keep the filtered agent in the map even with zero docs; after RepData so it is not a data row
	insert into #docs (Agent) values (@Agent);

	with TA as (select Agent from #docs where Agent is not null group by Agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, a.[Name]
	from cat.Agents a inner join TA on a.Id = TA.Agent;

	with TP as (select Operation from #docs group by Operation)
	select [!TOperation!Map] = null, [Id!!Id] = o.Id, o.[Name]
	from doc.Operations o inner join TP on o.Id = TP.Operation;

	select [Filter!TFilter!Object] = null,
		[Period.From!TPeriod!] = @From, [Period.To!TPeriod!] = @To, Run = @Run,
		[Agent!TAgent!RefId] = @Agent;
end
go
