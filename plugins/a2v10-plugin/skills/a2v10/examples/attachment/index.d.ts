// A file of the platform storage — always these four fields.
export interface TBlob extends IElement {
	readonly Id: number;
	Name: string;
	Mime: string;
	Token: string;
}

// A link of a2blob.BlobLinks.
export interface TAttachment extends IArrayElement {
	readonly Id: number;
	Blob: TBlob;
	// overrides
	readonly $parent: TAttachmentArray;
}
export declare type TAttachmentArray = IElementArray<TAttachment>;

// The owner: its record Id and its endpoint URL — exactly the data $uploadBlob takes.
export interface TOwner extends IElement {
	readonly Id: number;
	Base: string;
}

export interface TRoot extends IRoot {
	Owner: TOwner;
	Attachments: TAttachmentArray;
}
