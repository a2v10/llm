-- THE TYPE OF THE APPLICATION'S KEYS
--
-- Runs first in full.sql (see WebApp/sql.json), before the platform scripts: they use the type.
-- bigint, int or uniqueidentifier - chosen once, never changed afterwards.

------------------------------------------------
if type_id(N'dbo.platformid') is null
	create type dbo.platformid from bigint;
go
