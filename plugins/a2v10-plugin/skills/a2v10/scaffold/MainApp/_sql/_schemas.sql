-- SCHEMAS
--
-- Runs first in the bundle (see sql.json), before every /**/schema.sql — so tables always
-- find their schema. `create schema` must be the FIRST statement in its batch, which is why
-- it cannot sit under `if` directly and goes through sp_executesql instead.
-- A new schema beyond these four → add a block here (references/new-endpoint.md).

------------------------------------------------
-- catalogs
if not exists(select * from sys.schemas where name = N'cat')
	exec sp_executesql N'create schema cat';
go
------------------------------------------------
-- documents
if not exists(select * from sys.schemas where name = N'doc')
	exec sp_executesql N'create schema doc';
go
------------------------------------------------
-- journals / registers
if not exists(select * from sys.schemas where name = N'jrn')
	exec sp_executesql N'create schema jrn';
go
------------------------------------------------
-- reports
if not exists(select * from sys.schemas where name = N'rep')
	exec sp_executesql N'create schema rep';
go
