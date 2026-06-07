
export interface TSample extends IElement {
	readonly Id: number;
	Name: string;
	Memo: string;
	// override IElement
	readonly $root: TRoot;
}

export interface TRoot extends IRoot {
	Sample: TSample;
}
