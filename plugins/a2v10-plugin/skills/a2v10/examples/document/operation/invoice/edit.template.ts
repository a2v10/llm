
import { TDocument, TRow, TRoot } from "../edit";

const utils: Utils = require('std:utils');
const base = require('document/edit.template');


const template: Template = {
	validators: {
		'Document.Rows[].Qty': "@[Error.Required]"
	}
}

export default utils.mergeTemplate(base, template);

