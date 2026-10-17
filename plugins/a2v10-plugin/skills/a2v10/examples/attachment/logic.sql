-- Attachment: one endpoint for the whole application; the owner is addressed by base (its endpoint URL) + Id.
-- No tables of its own: links live in the platform's a2blob.BlobLinks, files in a2blob.Blobs.
------------------------------------------------
create or alter procedure cat.[Attachment.Index]
@UserId bigint,
@Id bigint,
@Base nvarchar(255)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	-- the context of the dialog: whose attachments, under which base ($uploadBlob sends it back)
	select [Owner!TOwner!Object] = null, [Id!!Id] = @Id, [Base] = @Base;

	select [Attachments!TAttachment!Array] = null, [Id!!Id] = l.Id, [Blob!TBlob!RefId] = l.[Blob]
	from a2blob.BlobLinks l
	where l.[Base] = @Base and l.LinkId = @Id
	order by l.Id;

	select [!TBlob!Map] = null, [Id!!Id] = b.Id, b.[Name], b.Mime, [Token!!Token] = b.AccessToken
	from a2blob.Blobs b
		inner join a2blob.BlobLinks l on b.Id = l.[Blob]
	where l.[Base] = @Base and l.LinkId = @Id;
end
go
------------------------------------------------
-- never by the link id alone: base + owner, or a foreign link id removes nothing
create or alter procedure cat.[Attachment.Delete]
@UserId bigint,
@Id bigint,
@Base nvarchar(255),
@Owner bigint
as
begin
	set nocount on;
	set transaction isolation level read committed;

	delete from a2blob.BlobLinks where Id = @Id and [Base] = @Base and LinkId = @Owner;
end
go
