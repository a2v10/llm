------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'cat' and SEQUENCE_NAME = N'SQ_Samples')
	create sequence cat.SQ_Samples as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'cat' and TABLE_NAME=N'Samples')
create table cat.[Samples]
(
	Id bigint not null
		constraint DF_Samples_Id default(next value for cat.SQ_Samples)
		constraint PK_Samples primary key,
	IsSystem bit not null
		constraint DF_Samples_IsSystem default(0),
	Void bit not null
		constraint DF_Samples_Void default(0),
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
);
go
