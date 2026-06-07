export interface TSample extends IArrayElement {
	readonly Id: number;
	Name: string;
	Memo: string;
	// overrides
	readonly $parent: TSampleArray;
}

export declare type TSampleArray = IElementArray<TSample>;

export interface TRoot {
	readonly Samples: TSampleArray;
}