export interface TAgent extends IElement {
	readonly Id: number;
	Name: string;
}

export interface TItem extends IElement {
	readonly Id: number;
	Name: string;
}

export interface TRow extends IArrayElement {
	readonly Id: number;
	readonly RowNo: number;
	Item: TItem;
	Qty: number;
	Price: number;
	Sum: number;
	// overrides
	readonly $parent: TRowArray;
}

export declare type TRowArray = IElementArray<TRow>;

export interface TDocument extends IElement {
	readonly Id: number;
	No: string;
	Date: Date;
	Operation: string;
	Agent: TAgent;
	Memo: string;
	Rows: TRowArray;
	// override
	readonly $root: TRoot;
}

export interface TRoot extends IRoot {
	Document: TDocument;
}
