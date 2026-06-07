------------------------------------------------
-- Реєстрація операції в doc.Operations
------------------------------------------------
if not exists (select 1 from doc.Operations where Id = N'invoice')
	insert into doc.Operations (Id, [Name]) values (N'invoice', N'Рахунок');
go
