import { TAgent, TWarehouse } from './edit';

export interface TDocument extends IArrayElement {
	readonly Id: number;
	readonly No: string;
	readonly Date: Date;
	readonly Operation: string;
	readonly Agent: TAgent;
	readonly Sum: number;
	readonly Memo: string;
	// overrides
	readonly $parent: TDocumentArray;
}

export declare type TDocumentArray = IElementArray<TDocument>;

export interface TRoot {
	readonly Documents: TDocumentArray;
}
