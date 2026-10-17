-- the type of the application's keys: the same as "platformid" in app.json, never changed afterwards
if type_id(N'dbo.platformid') is null
	create type dbo.platformid from bigint;
go
