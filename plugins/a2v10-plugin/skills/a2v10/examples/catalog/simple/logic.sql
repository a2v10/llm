-- Sample logic
------------------------------------------------
create or alter procedure cat.[Sample.Index]
@UserId bigint,
@Id bigint = null,
@Offset int = 0,
@PageSize int = 20,
@Order nvarchar(32) = N'name',
@Dir nvarchar(5) = N'asc',
@Fragment nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Fragment + N'%';
	set @Order = lower(@Order);
	set @Dir = lower(@Dir);

	declare @samples table(id bigint, rowNo int identity (1, 1), [rowCount] int);

	insert into @samples (id, [rowCount])
	select s.Id, count(*) over()
	from cat.[Samples] s
	where s.Void = 0 and (@fr is null or s.[Name] like @fr or s.Memo like @fr)
	order by 
		case when @Dir = N'asc' then
			case @Order
				when N'name' then s.[Name]
				when N'memo' then s.[Memo]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'name' then s.[Name]
				when N'memo' then s.[Memo]
			end
		end desc,
		case when @Dir = N'asc' then
			case @Order
				when N'id' then s.[Id]
			end
		end asc,
		case when @Dir = N'desc' then
			case @Order
				when N'id' then s.[Id]
			end
		end desc,
		s.Id
		offset @Offset rows fetch next @PageSize rows only 
		option(recompile);

	select [Samples!TSample!Array] = null,
		[Id!!Id] = s.Id, [Name!!Name] = s.[Name], s.Memo,
		[!!RowCount] = t.[rowCount]
	from cat.Samples s
		inner join @samples t on s.Id = t.Id
	order by t.rowNo;


	select [!$System!] = null, [!Samples!Offset] = @Offset, [!Samples!PageSize] = @PageSize, 
		[!Samples!SortOrder] = @Order, [!Samples!SortDir] = @Dir,
		[!Samples.Fragment!Filter] = @Fragment;
end
go
------------------------------------------------
create or alter procedure cat.[Sample.Load]
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Sample!TSample!Object] = null, [Id!!Id] = s.Id, [Name!!Name] = s.[Name], s.Memo
	from cat.[Samples] s
	where s.Id = @Id;
end
go
-------------------------------------------------
drop procedure if exists cat.[Sample.Metadata];
drop procedure if exists cat.[Sample.Update];
drop type if exists cat.[Sample.TableType];
go
-------------------------------------------------
create type cat.[Sample.TableType]
as table(
	Id bigint null,
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
);
go
------------------------------------------------
create or alter procedure cat.[Sample.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Sample cat.[Sample.TableType];
	select [Sample!Sample!Metadata] = null, * from @Sample;
end
go
------------------------------------------------
create or alter procedure cat.[Sample.Update]
@UserId bigint,
@Sample cat.[Sample.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;

	declare @rtable table(id bigint);
	declare @id bigint;

	merge cat.Samples as t
	using @Sample as s
	on t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo]
	when not matched by target then insert
		([Name], Memo) values
		(s.[Name], s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @id = id from @rtable;

	exec cat.[Sample.Load] @UserId = @UserId, @Id = @id;
end
go
------------------------------------------------
create or alter procedure cat.[Sample.Fetch]
@UserId bigint,
@Text nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @fr nvarchar(255);
	set @fr = N'%' + @Text + N'%';

	select top(100) [Samples!TSample!Array] = null, [Id!!Id] = s.Id, [Name!!Name] = s.[Name], s.Memo
	from cat.Samples s
	where Void = 0 and ([Name] like @fr or Memo like @fr)
	order by s.[Name];
end
go
---------------------------------------------
create or alter procedure cat.[Sample.Delete]
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	update cat.Samples set Void = 1 where Id=@Id;
end
go
