------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA = 'cat' and SEQUENCE_NAME = 'SQ_CurrencyRates')
	create sequence cat.SQ_CurrencyRates as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA='cat' and TABLE_NAME='CurrencyRates')
create table cat.[CurrencyRates]
(
	Id bigint not null
		constraint DF_CurrencyRates_Id default(next value for cat.SQ_CurrencyRates)
		constraint PK_CurrencyRates primary key,
	[Code] nvarchar(8) not null,
	[Name] nvarchar(255),
	[Date] date not null,
	[Rate] money not null
		constraint DF_CurrencyRates_Rate default(0)
);
go
------------------------------------------------
-- natural key: the merge in logic.sql matches on it
if not exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
	where TABLE_SCHEMA='cat' and TABLE_NAME='CurrencyRates' and CONSTRAINT_NAME='UQ_CurrencyRates_Code_Date')
	alter table cat.[CurrencyRates] add constraint UQ_CurrencyRates_Code_Date unique ([Code], [Date]);
go
