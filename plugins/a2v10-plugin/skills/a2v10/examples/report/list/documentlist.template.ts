// Concrete report template: only the computed total. The whole lifecycle
// (generate / dirty / loading / Run) comes from the shared _plain engine.
const baseTemplate = require("/reports/_common/_plain.template");
const utils: Utils = require("std:utils");

const template: Template = {
	properties: {
		'TRepDataArray.Sum'() { return this.$sum(r => r.Sum); }
	}
};

export default utils.mergeTemplate(baseTemplate, template);
