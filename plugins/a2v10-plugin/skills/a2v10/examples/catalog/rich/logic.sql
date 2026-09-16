-- Agent logic (rich catalog)
------------------------------------------------
create or alter procedure cat.[Agent.Index]
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'name',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null,
@State bigint = null,
@Tags nvarchar(max) = null -- TagsFilter: tag ids joined by '-'
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @ftags table(id bigint);
	insert into @ftags(id) select TRY_CAST([value] as bigint) from STRING_SPLIT(@Tags, N'-');

	declare @agents table(id bigint, rowNo int identity(1, 1), [rowCount] int);

	insert into @agents(id, [rowCount])
	select a.Id, count(*) over()
	from cat.Agents a
	where a.Void = 0
		and (@fr is null or a.[Name] like @fr or a.Memo like @fr)
		and (@State is null or a.[State] = @State)
		-- any of the selected tags
		and (@Tags is null or exists(
			select 1 from @ftags f inner join cat.AgentTags ta on ta.Agent = a.Id and ta.Tag = f.id
		))
	order by
		case when @Dir = N'asc'  then case @Order when N'name' then a.[Name] end end asc,
		case when @Dir = N'desc' then case @Order when N'name' then a.[Name] end end desc,
		case when @Dir = N'asc'  then case @Order when N'id'   then a.Id     end end asc,
		case when @Dir = N'desc' then case @Order when N'id'   then a.Id     end end desc,
		a.Id
		offset @Offset rows fetch next @PageSize rows only
	option(recompile);

	select [Agents!TAgent!Array] = null,
		[Id!!Id] = a.Id, [Name!!Name] = a.[Name],
		[Manager!TEmployee!RefId] = a.Manager,
		[State!TAgentState!RefId] = a.[State],
		a.IsCustomer, a.IsSupplier,
		[Tags!TTag!Array] = null,
		[!!RowCount] = t.[rowCount]
	from cat.Agents a
		inner join @agents t on a.Id = t.Id
	order by t.rowNo;

	-- tags per row (child array for the list) — rendered by <TagsList> in index.view
	select [!TTag!Array] = null, [Id!!Id] = tg.Id, [Name!!Name] = tg.[Name], tg.Color,
		[!TAgent.Tags!ParentId] = ta.Agent
	from cat.AgentTags ta
		inner join @agents t on ta.Agent = t.id
		inner join cat.Tags tg on ta.Tag = tg.Id
	order by tg.Id;

	-- [linked] maps for RefId
	select [!TEmployee!Map] = null, [Id!!Id] = e.Id, [Name!!Name] = e.[Name]
	from cat.Employees e
	where e.Id in (select a.Manager from cat.Agents a inner join @agents t on a.Id = t.Id where a.Manager is not null);

	select [!TAgentState!Map] = null, [Id!!Id] = s.Id, [Name!!Name] = s.[Name], s.Color
	from cat.AgentStates s
	where s.Id in (select a.[State] from cat.Agents a inner join @agents t on a.Id = t.Id where a.[State] is not null);

	-- available tags for this entity — root-level collection (TagsFilter ItemsSource)
	select [Tags!TTag!Array] = null, [Id!!Id] = tg.Id, [Name!!Name] = tg.[Name], tg.Color
	from cat.Tags tg
	where tg.[For] = N'Agent'
	order by tg.[Name];

	select [!$System!] = null,
		[!Agents!Offset] = @Offset, [!Agents!PageSize] = @PageSize,
		[!Agents!SortOrder] = @Order, [!Agents!SortDir] = @Dir,
		[!Agents.Fragment!Filter] = @Fragment,
		[!Agents.State.TAgentState.RefId!Filter] = @State,
		[!Agents.Tags!Filter] = @Tags;
end
go
------------------------------------------------
create or alter procedure cat.[Agent.Load]
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	-- header
	select [Agent!TAgent!Object] = null,
		[Id!!Id] = a.Id, [Name!!Name] = a.[Name], a.Memo,
		[Manager!TEmployee!RefId] = a.Manager,
		[State!TAgentState!RefId] = a.[State],
		a.IsCustomer, a.IsSupplier,
		[Addresses!TAddress!Array] = null,
		[Accounts!TAccount!Array] = null,
		[Tags!TAgentTag!Array] = null
	from cat.Agents a
	where a.Id = @Id;

	-- table part #1 — addresses (plain scalars)
	select [!TAddress!Array] = null,
		[Id!!Id] = r.Id, [RowNo!!RowNumber] = r.RowNo,
		r.Kind, r.City, r.Street, r.Zip,
		[!TAgent.Addresses!ParentId] = r.Agent
	from cat.AgentAddresses r
	where r.Agent = @Id
	order by r.RowNo;

	-- table part #2 — accounts (two RefId in a row)
	select [!TAccount!Array] = null,
		[Id!!Id] = r.Id, [RowNo!!RowNumber] = r.RowNo,
		[Bank!TBank!RefId] = r.Bank,
		[Currency!TCurrency!RefId] = r.Currency,
		r.Iban,
		[!TAgent.Accounts!ParentId] = r.Agent
	from cat.AgentAccounts r
	where r.Agent = @Id
	order by r.RowNo;

	-- many-to-many — tags (reference-only rows) — the linked tags (TagsControl Value)
	select [!TAgentTag!Array] = null,
		[Id!!Id] = at.Id,
		[Tag!TTag!RefId] = at.Tag,
		[!TAgent.Tags!ParentId] = at.Agent
	from cat.AgentTags at
	where at.Agent = @Id
	order by at.Id;

	-- available tags for this entity — root-level collection (TagsControl ItemsSource)
	select [Tags!TTag!Array] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color
	from cat.Tags t
	where t.[For] = N'Agent'
	order by t.[Name];

	-- [linked] maps for every RefId above
	select [!TEmployee!Map] = null, [Id!!Id] = e.Id, [Name!!Name] = e.[Name]
	from cat.Employees e where e.Id = (select Manager from cat.Agents where Id = @Id);

	select [!TAgentState!Map] = null, [Id!!Id] = s.Id, [Name!!Name] = s.[Name], s.Color
	from cat.AgentStates s where s.Id = (select [State] from cat.Agents where Id = @Id);

	select [!TBank!Map] = null, [Id!!Id] = b.Id, [Name!!Name] = b.[Name]
	from cat.Banks b where b.Id in (select Bank from cat.AgentAccounts where Agent = @Id and Bank is not null);

	select [!TCurrency!Map] = null, [Id!!Id] = cu.Id, [Name!!Name] = cu.[Name]
	from cat.Currencies cu where cu.Id in (select Currency from cat.AgentAccounts where Agent = @Id and Currency is not null);

	select [!TTag!Map] = null, [Id!!Id] = t.Id, [Name!!Name] = t.[Name], t.Color
	from cat.Tags t where t.Id in (select Tag from cat.AgentTags where Agent = @Id);
end
go
-------------------------------------------------
drop procedure if exists cat.[Agent.Metadata];
drop procedure if exists cat.[Agent.Update];
drop type if exists cat.[Agent.TableType];
drop type if exists cat.[Agent.Address.TableType];
drop type if exists cat.[Agent.Account.TableType];
drop type if exists cat.[Agent.Tag.TableType];
go
-------------------------------------------------
create type cat.[Agent.TableType]
as table(
	Id         bigint,
	[Name]     nvarchar(255),
	[Memo]     nvarchar(255),
	Manager    bigint,
	[State]    bigint,
	IsCustomer bit,
	IsSupplier bit
);
go
-------------------------------------------------
create type cat.[Agent.Address.TableType]
as table(
	Id      bigint,
	RowNo   int,
	Kind    nvarchar(50),
	City    nvarchar(255),
	Street  nvarchar(255),
	Zip     nvarchar(20)
);
go
-------------------------------------------------
create type cat.[Agent.Account.TableType]
as table(
	Id        bigint,
	RowNo     int,
	Bank      bigint,
	Currency  nvarchar(3),
	Iban      nvarchar(34)
);
go
-------------------------------------------------
create type cat.[Agent.Tag.TableType]
as table(
	Id    bigint,
	Tag   bigint
);
go
------------------------------------------------
create or alter procedure cat.[Agent.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Agent cat.[Agent.TableType];
	declare @Addresses cat.[Agent.Address.TableType];
	declare @Accounts cat.[Agent.Account.TableType];
	declare @Tags cat.[Agent.Tag.TableType];
	select [Agent!Agent!Metadata] = null, * from @Agent;
	select [Addresses!Agent.Addresses!Metadata] = null, * from @Addresses;
	select [Accounts!Agent.Accounts!Metadata] = null, * from @Accounts;
	select [Tags!Agent.Tags!Metadata] = null, * from @Tags;
end
go
------------------------------------------------
create or alter procedure cat.[Agent.Update]
@UserId bigint,
@Agent cat.[Agent.TableType] readonly,
@Addresses cat.[Agent.Address.TableType] readonly,
@Accounts cat.[Agent.Account.TableType] readonly,
@Tags cat.[Agent.Tag.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	-- header — single row, keyed by @id
	merge cat.Agents as t
	using @Agent as s on t.Id = s.Id
	when matched then update set
		t.[Name]     = s.[Name],
		t.Memo       = s.Memo,
		t.Manager    = s.Manager,
		t.[State]    = s.[State],
		t.IsCustomer = s.IsCustomer,
		t.IsSupplier = s.IsSupplier
	when not matched by target then insert
		([Name], Memo, Manager, [State], IsCustomer, IsSupplier) values
		(s.[Name], s.Memo, s.Manager, s.[State], s.IsCustomer, s.IsSupplier)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	-- table part #1 — addresses (linked by @id; no ParentGUID at this depth)
	merge cat.AgentAddresses as t
	using @Addresses as s on t.Id = s.Id and t.Agent = @id
	when matched then update set
		t.RowNo  = s.RowNo,
		t.Kind   = s.Kind,
		t.City   = s.City,
		t.Street = s.Street,
		t.Zip    = s.Zip
	when not matched by target then insert
		(Agent, RowNo, Kind, City, Street, Zip) values
		(@id, s.RowNo, s.Kind, s.City, s.Street, s.Zip)
	when not matched by source and t.Agent = @id then delete;

	-- table part #2 — accounts (linked by @id)
	merge cat.AgentAccounts as t
	using @Accounts as s on t.Id = s.Id and t.Agent = @id
	when matched then update set
		t.RowNo    = s.RowNo,
		t.Bank     = s.Bank,
		t.Currency = s.Currency,
		t.Iban     = s.Iban
	when not matched by target then insert
		(Agent, RowNo, Bank, Currency, Iban) values
		(@id, s.RowNo, s.Bank, s.Currency, s.Iban)
	when not matched by source and t.Agent = @id then delete;

	-- many-to-many — tags (same @id idiom; a reference-only table part)
	merge cat.AgentTags as t
	using @Tags as s on t.Id = s.Id and t.Agent = @id
	when matched then update set
		t.Tag = s.Tag
	when not matched by target then insert
		(Agent, Tag) values (@id, s.Tag)
	when not matched by source and t.Agent = @id then delete;

	exec cat.[Agent.Load] @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[Agent.Fetch]
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Agents!TAgent!Array] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name], a.Memo
	from cat.Agents a
	where a.Void = 0 and (a.[Name] like @fr or a.Memo like @fr)
	order by a.[Name];
end
go
------------------------------------------------
create or alter procedure cat.[Agent.Delete]
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.Agents set Void = 1 where Id = @Id;
end
go
