------------------------------------------------
-- doc.Operations — довідник видів операцій
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Operations')
create table doc.[Operations]
(
	Id nvarchar(20) not null
		constraint PK_Operations primary key,
	[Name] nvarchar(255)
);
go
------------------------------------------------
-- doc.Documents — шапка документів (всі операції)
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_Documents')
	create sequence doc.SQ_Documents as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'Documents')
create table doc.[Documents]
(
	Id bigint not null
		constraint DF_Documents_Id default(next value for doc.SQ_Documents)
		constraint PK_Documents primary key,
	Void bit not null
		constraint DF_Documents_Void default(0),
	[Date] date not null
		constraint DF_Documents_Date default(getdate()),
	[No] nvarchar(32),
	Operation nvarchar(20) not null,  -- FK → doc.Operations
	[Memo] nvarchar(255),
	[Sum] money not null
		constraint DF_Documents_Sum default(0),
	Agent bigint -- FK → cat.Agents
);
go
------------------------------------------------
-- doc.DocDetails — таблична частина документів
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = N'doc' and SEQUENCE_NAME = N'SQ_DocDetails')
	create sequence doc.SQ_DocDetails as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'DocDetails')
create table doc.[DocDetails]
(
	Id bigint not null
		constraint DF_DocDetails_Id default(next value for doc.SQ_DocDetails)
		constraint PK_DocDetails primary key,
	Document bigint not null,         -- [owner] FK → doc.Documents
	RowNo int not null,               -- [row number]
	Qty float not null
		constraint DF_DocDetails_Qty default(0),
	Price money not null
		constraint DF_DocDetails_Price default(0),
	[Sum] money not null
		constraint DF_DocDetails_Sum default(0),
	Item bigint -- FK → cat.Items
);
go
------------------------------------------------
-- doc.OpLinks — правила зв'язків між операціями
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'OpLinks')
create table doc.[OpLinks]
(
	Id int not null identity
		constraint PK_OpLinks primary key,
	Parent nvarchar(20) not null, -- FK → doc.Operations
	Child  nvarchar(20) not null, -- FK → doc.Operations
	Kind   nvarchar(50) not null,
	constraint UQ_OpLinks_Key unique (Parent, Child, Kind)
);
go
------------------------------------------------
-- doc.OpTrans — правила проведення по журналах
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'OpTrans')
create table doc.[OpTrans]
(
	Operation nvarchar(20) not null, -- FK → doc.Operations
	Journal   nvarchar(20) not null,
	Dir       smallint not null,    -- +1 прихід, -1 видаток
	Storno    smallint not null
		constraint DF_OpTrans_Storno default(1),
	constraint PK_OpTrans primary key (Operation, Journal, Dir),
	constraint CK_OpTrans_Dir    check (Dir    in (1, -1)),
	constraint CK_OpTrans_Storno check (Storno in (1, -1))
);
go
------------------------------------------------
-- doc.DocLinks — фактичні зв'язки між документами
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = N'doc' and TABLE_NAME = N'DocLinks')
create table doc.[DocLinks]
(
	ParentId bigint not null, -- FK → doc.Documents
	ChildId  bigint not null, -- FK → doc.Documents 
	LinkId   int not null,
	constraint PK_DocLinks primary key (ParentId, ChildId, LinkId)
);
go
