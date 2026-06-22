// Shared engine for on-screen reports (lifecycle + generate). See references/screen-report.md.
const utils: Utils = require('std:utils');

const template: Template = {
	options: {
		noDirty: true
	},
	properties: {
		'TRoot.$$Tab': String,
		'TRoot.$$Dirty': Boolean,
		'TRoot.$$Loading': Boolean,
		'TRoot.$AlertVisible'() { return this.$$Dirty && !this.$$Loading && this.Filter.Run; },
		'TRoot.$SheetPageClass'() { return 'sheet-page' + (this.$AlertVisible ? ' sheet-dirty' : '') },
		'TRoot.$Title': repTitle
	},
	events: {
		'Model.dirty.change': modelChanged
	},
	commands: {
		generate
	}
};

export default template;

function modelChanged(dirty, prop) {
	if (!dirty) return;
	this.$$Dirty = true;
}

function repTitle() {
	let r = 'Report';
	if (this.Filter.Period)
		r += ` [${this.Filter.Period.Name}]`;
	return r;
}

function generate() {
	const ctrl: IController = this.$ctrl;

	let filter: any = {
		Run: true
	};

	this.$$Loading = true;

	let defNames = ['Run'];

	let repFilter = this.Filter;
	for (let fld of Object.getOwnPropertyNames(repFilter)
		.filter(f => !f.startsWith('_') && !f.startsWith('$') && !defNames.includes(f))) {
		let el = repFilter[fld];
		// flatten a filter field to a URL param: Period → DateUrl, object → .Id, array → .$ids
		if (fld === 'Period')
			filter[fld] = repFilter.Period.format(DataType.DateUrl);
		else if (utils.isObjectExact(el))
			filter[fld] = el.Id;
		else if (Array.isArray(el))
			filter[fld] = (el as any).$ids;
		else filter[fld] = el;
	}
	ctrl.$requery(filter);
}
