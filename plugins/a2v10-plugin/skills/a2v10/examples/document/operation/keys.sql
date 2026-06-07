------------------------------------------------
-- FK від doc.Documents до doc.Operations
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = N'FK_Documents_Operation_Operations')
	alter table doc.Documents add
		constraint FK_Documents_Operation_Operations foreign key (Operation) references doc.Operations(Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = N'FK_Documents_Agent_Agents')
	alter table doc.Documents add
		constraint FK_Documents_Agent_Agents foreign key (Agent) references cat.Agents(Id);
go
------------------------------------------------
-- FK від doc.DocDetails
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = N'FK_DocDetails_Document_Documents')
	alter table doc.DocDetails add
		constraint FK_DocDetails_Document_Documents foreign key (Document) references doc.Documents(Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = N'FK_DocDetails_Item_Items')
	alter table doc.DocDetails add
		constraint FK_DocDetails_Item_Items foreign key (Item) references cat.Items(Id);
go
------------------------------------------------
-- FK від doc.DocLinks
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = N'FK_DocLinks_ParentId_Documents')
	alter table doc.DocLinks add
		constraint FK_DocLinks_ParentId_Documents foreign key (ParentId) references doc.Documents(Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = N'FK_DocLinks_ChildId_Documents')
	alter table doc.DocLinks add
		constraint FK_DocLinks_ChildId_Documents foreign key (ChildId) references doc.Documents(Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = N'FK_DocLinks_LinkId_OpLinks')
	alter table doc.DocLinks add
		constraint FK_DocLinks_LinkId_OpLinks foreign key (LinkId) references doc.OpLinks(Id);
go
