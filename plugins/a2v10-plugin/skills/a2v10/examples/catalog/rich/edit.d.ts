// Reference (FK) targets — each is {Id, Name}, resolved via a Map result set.
export interface TEmployee extends IElement {
	readonly Id: number;
	Name: string;
}

export interface TAgentState extends IElement {
	readonly Id: number;
	Name: string;
	Color: string; // CSS class for the badge
}

export interface TBank extends IElement {
	readonly Id: number;
	Name: string;
}

export interface TCurrency extends IElement {
	readonly Id: string; // ISO code
	Name: string;
}

export interface TTag extends IElement {
	readonly Id: number;
	Name: string;
	Color: string;
}
export declare type TTagArray = IElementArray<TTag>;

// Table part #1 — addresses (plain scalars)
export interface TAddress extends IArrayElement {
	readonly Id: number;
	readonly RowNo: number;
	Kind: string;
	City: string;
	Street: string;
	Zip: string;
	// overrides
	readonly $parent: TAddressArray;
}
export declare type TAddressArray = IElementArray<TAddress>;

// Table part #2 — accounts (two references in a row)
export interface TAccount extends IArrayElement {
	readonly Id: number;
	readonly RowNo: number;
	Bank: TBank;
	Currency: TCurrency;
	Iban: string;
	// overrides
	readonly $parent: TAccountArray;
}
export declare type TAccountArray = IElementArray<TAccount>;

// Many-to-many — tags (a reference-only row)
export interface TAgentTag extends IArrayElement {
	readonly Id: number;
	Tag: TTag;
	// overrides
	readonly $parent: TAgentTagArray;
}
export declare type TAgentTagArray = IElementArray<TAgentTag>;

export interface TAgent extends IElement {
	readonly Id: number;
	Name: string;
	Memo: string;
	Manager: TEmployee;
	State: TAgentState;
	IsCustomer: boolean;
	IsSupplier: boolean;
	Addresses: TAddressArray;
	Accounts: TAccountArray;
	Tags: TAgentTagArray;
	// override IElement
	readonly $root: TRoot;
}

export interface TRoot extends IRoot {
	Agent: TAgent;
	Tags: TTagArray; // ItemsSource pool for TagsControl (all tags where [For] = 'Agent')
}
