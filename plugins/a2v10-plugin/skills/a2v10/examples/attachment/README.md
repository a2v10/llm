# Example: attachment — files attached to any record

**One endpoint for the whole application** (`/attachment`), not one per entity. The owner is
addressed by two values: `base` — the owner's endpoint URL — and the record `Id`. The files live in
the platform tables (`a2blob.Blobs`, links in `a2blob.BlobLinks`); the app writes no table and no
`schema.sql` for them. Caller in this skill: `catalog/rich` (the **Attachments** button).

## Files

| File                 | Purpose                                                       |
|----------------------|---------------------------------------------------------------|
| `model.json`         | `requireBase`; dialog `index`; `blobs.Upload`; command `delete` |
| `logic.sql`          | `Attachment.Index`, `Attachment.Delete`                        |
| `index.d.ts`         | `TOwner`, `TAttachment`, `TBlob`                               |
| `index.template.ts`  | `upload` (`$uploadBlob`), `remove` (`$invoke('delete')`)       |
| `index.dialog.vxaml` | List of files + `<BlobPreview>` of the selected one            |

## Design notes

**The caller.** The owner's form opens the dialog with the owner as `Argument` and its own endpoint
in `base`; `SaveRequired=True` saves a new record first, so its `Id` exists:

```xml
<Button Content="@[Attachments]" Icon="Attach"
	Command="{BindCmd Dialog, Action=Show, Argument={Bind Agent}, Url='/attachment/index?base=/catalog/agent', SaveRequired=True}"/>
```

**`requireBase`.** Every call must carry `base`; the platform checks the roles of the `model.json`
at that URL before calling the procedure. `Upload` in `blobs` is not a model field — just the name
uploads go to (`/attachment/upload`).

**Every procedure filters by `@Base` + owner.** The roles of `base` stop only a user with no access
to any owner; a foreign `base` or link `Id` must find nothing. `Delete` therefore matches all three
values, never the link `Id` alone.

**The owner's delete.** `LinkId` has no FK to the owner, so links outlive it. A soft delete (`Void`)
keeps them; a hard delete of the owner removes them itself:
`delete from a2blob.BlobLinks where [Base] = N'/catalog/agent' and LinkId = @Id`. The `base` value
lives in two places — the caller's URL and that delete — change one, change the other.

**No file deletion.** A removed link, a replaced logo, an upload never saved — the file stays in the
storage. A file is immutable: a replacement always has a new `Id`.

**The host's storage.** Uploading needs a storage registered by the host — the same three pieces as
for a file in a record field (→ `references/add-field.md`, *File / image*).

Full mechanics → [sql/blob-storage.md](https://docs-llm.a2v10.com/sql/blob-storage.md).
