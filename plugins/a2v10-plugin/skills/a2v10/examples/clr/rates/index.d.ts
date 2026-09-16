export interface TRate extends IArrayElement {
	readonly Id: number;
	readonly Code: string;
	readonly Name: string;
	readonly Date: Date;
	readonly Rate: number;
	// overrides
	readonly $parent: TRateArray;
}

export declare type TRateArray = IElementArray<TRate>;

export interface TRoot {
	readonly Rates: TRateArray;
}
