import { TDocument, TRow, TRoot } from "./edit";

const utils: Utils = require('std:utils');

const template: Template = {
	properties: {
		'TRoot.$$Tab': String,
		'TRow.Sum'(this: TRow): number { return this.Qty * this.Price; },
		'TDocument.Sum'(this: TDocument): number { return this.Rows.$sum(r => r.Sum); }
	},
	validators: {
		'Document.No': "@[Error.Required]",
		'Document.Date': "@[Error.Required]"
	},
	defaults: {
		'Document.Date'() { return utils.date.today(); }
	}
}

export default template;
