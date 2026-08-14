import { TEmployee, TAgentState, TTagArray } from "./edit";

export interface TAgent extends IArrayElement {
	readonly Id: number;
	readonly Name: string;
	readonly Manager: TEmployee;
	readonly State: TAgentState;
	readonly IsCustomer: boolean;
	readonly IsSupplier: boolean;
	readonly Tags: TTagArray; // per-row tags, rendered by <TagsList>
	// overrides
	readonly $parent: TAgentArray;
}

export declare type TAgentArray = IElementArray<TAgent>;

export interface TRoot {
	readonly Agents: TAgentArray;
}
