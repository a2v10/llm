-- Document logic (operation)
-------------------------------------------------
drop procedure if exists doc.[Document.Map];
drop type if exists doc.[Document.Map.TableType];
go
-------------------------------------------------
create type doc.[Document.Map.TableType]
as table(
	id          bigint,
	rowNo       int identity(1, 1),
	agent		bigint,
	item		bigint,
	[rowCount]  int
);
go
-------------------------------------------------
create or alter procedure doc.[Document.Map]
@Map doc.[Document.Map.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	
	-- [linked] Map контрагентів для RefId 
	with TA as (select agent from @Map where agent is not null group by agent)
	select [!TAgent!Map] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name]
	from cat.Agents a
		inner join TA on a.Id = TA.agent;	

	-- [linked] Map номенклатури для RefId 
	with TI as (select item from @Map where item is not null group by item)
	select [!TItem!Map] = null, [Id!!Id] = i.Id, [Name!!Name] = i.[Name]
	from cat.Items i
		inner join TI on i.Id = TI.item;	
end
go
------------------------------------------------
create or alter procedure doc.[Document.Index]
@UserId bigint,
@Operation nvarchar(20),
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'date',
@Dir nvarchar(5) = N'desc',
@From date = null,
@To date = null,
@Fragment nvarchar(255) = null,
@Agent bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @docs doc.[Document.Map.TableType];

	insert into @docs(id, agent, [rowCount])
	select d.Id, d.Agent, count(*) over()
	from doc.Documents d
		left join cat.Agents a on d.Agent = a.Id
	where d.Void = 0
		and d.Operation = @Operation
		and (@Agent is null or d.Agent = @Agent)
		and (@From is null or d.[Date] >= @From)
		and (@To is null or d.[Date] <= @To)
		and (@fr is null or d.[No] like @fr or d.[Memo] like @fr or a.[Name] like @fr)
	order by
		case when @Dir = N'asc'  then case @Order when N'no'   then d.[No]   end end asc,
		case when @Dir = N'desc' then case @Order when N'no'   then d.[No]   end end desc,
		case when @Dir = N'asc'  then case @Order when N'date' then d.[Date] end end asc,
		case when @Dir = N'desc' then case @Order when N'date' then d.[Date] end end desc,
		case when @Dir = N'asc'  then case @Order when N'id'   then d.Id     end end asc,
		case when @Dir = N'desc' then case @Order when N'id'   then d.Id     end end desc,
		case when @Dir = N'asc'  then case @Order when N'sum'  then d.[Sum]  end end asc,
		case when @Dir = N'desc' then case @Order when N'sum'  then d.[Sum]  end end desc,
		d.Id
		offset @Offset rows fetch next @PageSize rows only
	option(recompile);

	select [Documents!TDocument!Array] = null,
		[Id!!Id] = d.Id, [No!!Name] = d.[No], d.[Date], d.Operation,
		d.[Sum],
		d.Memo, 
		[Agent!TAgent!RefId] = d.Agent,
		[!!RowCount] = t.[rowCount]
	from doc.Documents d
		inner join @docs t on d.Id = t.Id
	order by t.rowNo;

	exec doc.[Document.Map] @Map = @docs; -- [linked] resolve RefId

	select [!$System!] = null,
		-- pager
		[!Documents!Offset]	= @Offset, [!Documents!PageSize] = @PageSize, [!Documents!SortOrder] = @Order, [!Documents!SortDir] = @Dir,
		-- filters
		[!Documents.Period.From!Filter] = @From, [!Documents.Period.To!Filter] = @To,
		[!Documents.Fragment!Filter] = @Fragment, [!Documents.Agent.TAgent.RefId!Filter] = @Agent;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Load]
@UserId bigint,
@Id bigint = null,
@Operation nvarchar(20)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	-- шапка
	select [Document!TDocument!Object] = null,
		[Id!!Id] = d.Id, [No!!Name] = d.[No], d.[Date], d.[Sum],
		[Operation!TOperation!RefId] = d.Operation,
		d.Memo, [Agent!TAgent!RefId] = d.Agent,
		[Rows!TRow!Array] = null
	from doc.Documents d
	where d.Id = @Id;

	-- рядки
	select [!TRow!Array] = null,
		[Id!!Id] = r.Id,
		[RowNo!!RowNumber] = r.RowNo,
		r.Qty, r.Price, r.[Sum],
		[!TDocument.Rows!ParentId] = r.Document
	from doc.DocDetails r
	where r.Document = @Id
	order by r.RowNo;

	-- [linked] Map через Document.Map
	declare @map doc.[Document.Map.TableType];

	insert into @map(id, agent)
	select @Id, d.Agent
	from doc.Documents d where d.Id = @Id;

	insert into @map(item)
	select r.Item from doc.DocDetails r
	where r.Document = @Id and r.Item is not null;

	select [!TOperation!Map] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name],
		[Linked!TOpLink!Array] = null
	from doc.Operations o where Id = @Operation;

	exec doc.[Document.Map] @Map = @map;
end
go
-------------------------------------------------
drop procedure if exists doc.[Document.Metadata];
drop procedure if exists doc.[Document.Update];
drop type if exists doc.[Document.TableType];
drop type if exists doc.[Document.Row.TableType];
go
-------------------------------------------------
create type doc.[Document.TableType]
as table(
	Id          bigint,
	[Date]      date,
	[No]        nvarchar(32),
	Operation   nvarchar(20),
	[Memo]      nvarchar(255),
	[Sum]		money,
	Agent       bigint
);
go
-------------------------------------------------
create type doc.[Document.Row.TableType]
as table(
	Id          bigint,
	RowNo       int,
	Item        bigint,
	Qty         decimal(10,3),
	Price       decimal(10,2),
	[Sum]       decimal(10,2)
);
go
------------------------------------------------
create or alter procedure doc.[Document.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Document doc.[Document.TableType];
	declare @Rows doc.[Document.Row.TableType];
	select [Document!Document!Metadata] = null, * from @Document;
	select [Rows!Document.Rows!Metadata] = null, * from @Rows;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Update]
@UserId bigint,
@Document doc.[Document.TableType] readonly,
@Rows doc.[Document.Row.TableType] readonly,
@Operation nvarchar(20)
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge doc.Documents as t
	using @Document as s on t.Id = s.Id
	when matched then update set
		t.[Date]  = s.[Date],
		t.[No]    = s.[No],
		t.Memo    = s.Memo,
		t.[Sum]   = s.[Sum],
		t.Agent   = s.Agent
	when not matched by target then insert
		(Operation, [Date], [No], Memo, [Sum], Agent) values
		(@Operation, s.[Date], s.[No], s.Memo, s.[Sum], s.Agent)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	merge doc.DocDetails as t
	using @Rows as s on t.Id = s.Id and t.Document = @id
	when matched then update set
		t.RowNo  = s.RowNo,
		t.Item   = s.Item,
		t.Qty    = s.Qty,
		t.Price  = s.Price,
		t.[Sum]  = s.[Sum]
	when not matched by target then insert
		(Document, RowNo, Item, Qty, Price, [Sum]) values
		(@id, s.RowNo, s.Item, s.Qty, s.Price, s.[Sum])
	when not matched by source and t.Document = @id then delete;

	exec doc.[Document.Load] @UserId = @UserId, @Id = @id, @Operation = @Operation;
end
go
------------------------------------------------
create or alter procedure doc.[Document.Delete]
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update doc.Documents set Void = 1 where Id = @Id;
end
go
