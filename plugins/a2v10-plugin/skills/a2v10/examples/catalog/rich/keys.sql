------------------------------------------------
-- FK from cat.Agents (header references)
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = 'FK_Agents_Manager_Employees')
	alter table cat.Agents add
		constraint FK_Agents_Manager_Employees foreign key (Manager) references cat.Employees(Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = 'FK_Agents_State_AgentStates')
	alter table cat.Agents add
		constraint FK_Agents_State_AgentStates foreign key ([State]) references cat.AgentStates(Id);
go
------------------------------------------------
-- FK from cat.AgentAddresses
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = 'FK_AgentAddresses_Agent_Agents')
	alter table cat.AgentAddresses add
		constraint FK_AgentAddresses_Agent_Agents foreign key (Agent) references cat.Agents(Id);
go
------------------------------------------------
-- FK from cat.AgentAccounts (owner + two references)
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = 'FK_AgentAccounts_Agent_Agents')
	alter table cat.AgentAccounts add
		constraint FK_AgentAccounts_Agent_Agents foreign key (Agent) references cat.Agents(Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = 'FK_AgentAccounts_Bank_Banks')
	alter table cat.AgentAccounts add
		constraint FK_AgentAccounts_Bank_Banks foreign key (Bank) references cat.Banks(Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = 'FK_AgentAccounts_Currency_Currencies')
	alter table cat.AgentAccounts add
		constraint FK_AgentAccounts_Currency_Currencies foreign key (Currency) references cat.Currencies(Id);
go
------------------------------------------------
-- FK from cat.AgentTags (owner + reference)
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = 'FK_AgentTags_Agent_Agents')
	alter table cat.AgentTags add
		constraint FK_AgentTags_Agent_Agents foreign key (Agent) references cat.Agents(Id);
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS where CONSTRAINT_NAME = 'FK_AgentTags_Tag_Tags')
	alter table cat.AgentTags add
		constraint FK_AgentTags_Tag_Tags foreign key (Tag) references cat.Tags(Id);
go
