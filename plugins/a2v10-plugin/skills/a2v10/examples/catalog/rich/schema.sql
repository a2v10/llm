------------------------------------------------
-- Stub reference catalogs (FK targets for cat.Agents).
-- Minimal by design: in a real project each is a full catalog of its own
-- (own model.json, views, procedures). Here they exist only so Agent's FKs,
-- Map result sets and selectors resolve.
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'cat' and TABLE_NAME = 'Employees')
create table cat.[Employees]
(
	Id bigint not null identity(100, 1) constraint PK_Employees primary key,
	[Name] nvarchar(255)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'cat' and TABLE_NAME = 'AgentStates')
create table cat.[AgentStates]
(
	Id bigint not null identity(1, 1) constraint PK_AgentStates primary key,
	[Name] nvarchar(255),
	Color nvarchar(50) -- CSS class for the badge (e.g. 'text-success', 'text-danger')
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'cat' and TABLE_NAME = 'Banks')
create table cat.[Banks]
(
	Id bigint not null identity(100, 1) constraint PK_Banks primary key,
	[Name] nvarchar(255),
	Swift nvarchar(11)
);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'cat' and TABLE_NAME = 'Currencies')
create table cat.[Currencies]
(
	Id nvarchar(3) not null constraint PK_Currencies primary key, -- ISO code, e.g. 'USD'
	[Name] nvarchar(255)
);
go
------------------------------------------------
-- cat.Tags is a shared/generic dictionary (not Agent-specific): one tags table for
-- every entity, discriminated by [For]. The m2m binding stays per-entity (cat.AgentTags).
-- A full Tags catalog + the dedicated tag control are a separate example.
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'cat' and TABLE_NAME = 'Tags')
create table cat.[Tags]
(
	Id bigint not null identity(100, 1) constraint PK_Tags primary key,
	[For] nvarchar(32) not null, -- entity kind the tag applies to (matches model.json "model"), here 'Agent'
	[Name] nvarchar(255),
	Color nvarchar(50) -- chip color for TagsList / TagsControl
);
go
------------------------------------------------
-- cat.Agents — the rich catalog (header)
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = 'cat' and SEQUENCE_NAME = 'SQ_Agents')
	create sequence cat.SQ_Agents as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'cat' and TABLE_NAME = 'Agents')
create table cat.[Agents]
(
	Id bigint not null
		constraint DF_Agents_Id default(next value for cat.SQ_Agents)
		constraint PK_Agents primary key,
	IsSystem bit not null
		constraint DF_Agents_IsSystem default(0),
	Void bit not null
		constraint DF_Agents_Void default(0),
	[Name] nvarchar(255),
	[Memo] nvarchar(255),
	Manager bigint,    -- FK → cat.Employees   (plain single reference)
	[State] bigint,    -- FK → cat.AgentStates (reference rendered with a color)
	IsCustomer bit not null
		constraint DF_Agents_IsCustomer default(0),
	IsSupplier bit not null
		constraint DF_Agents_IsSupplier default(0)
);
go
------------------------------------------------
-- cat.AgentAddresses — table part #1 (plain scalars, no FK)
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = 'cat' and SEQUENCE_NAME = 'SQ_AgentAddresses')
	create sequence cat.SQ_AgentAddresses as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'cat' and TABLE_NAME = 'AgentAddresses')
create table cat.[AgentAddresses]
(
	Id bigint not null
		constraint DF_AgentAddresses_Id default(next value for cat.SQ_AgentAddresses)
		constraint PK_AgentAddresses primary key,
	Agent bigint not null, -- [owner] FK → cat.Agents
	RowNo int not null,
	Kind nvarchar(50),
	City nvarchar(255),
	Street nvarchar(255),
	Zip nvarchar(20)
);
go
------------------------------------------------
-- cat.AgentAccounts — table part #2 (two references in a row: Bank, Currency)
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = 'cat' and SEQUENCE_NAME = 'SQ_AgentAccounts')
	create sequence cat.SQ_AgentAccounts as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'cat' and TABLE_NAME = 'AgentAccounts')
create table cat.[AgentAccounts]
(
	Id bigint not null
		constraint DF_AgentAccounts_Id default(next value for cat.SQ_AgentAccounts)
		constraint PK_AgentAccounts primary key,
	Agent bigint not null, -- [owner] FK → cat.Agents
	RowNo int not null,
	Bank bigint,           -- FK → cat.Banks
	Currency nvarchar(3),  -- FK → cat.Currencies
	Iban nvarchar(34)
);
go
------------------------------------------------
-- cat.AgentTags — many-to-many link (a reference-only table part)
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = 'cat' and SEQUENCE_NAME = 'SQ_AgentTags')
	create sequence cat.SQ_AgentTags as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'cat' and TABLE_NAME = 'AgentTags')
create table cat.[AgentTags]
(
	Id bigint not null
		constraint DF_AgentTags_Id default(next value for cat.SQ_AgentTags)
		constraint PK_AgentTags primary key,
	Agent bigint not null, -- [owner] FK → cat.Agents
	Tag bigint not null,   -- FK → cat.Tags
	constraint UQ_AgentTags_Key unique (Agent, Tag)
);
go
