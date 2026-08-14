import { TRoot, TAgent, TTagArray } from "./edit";

const template: Template = {
	properties: {
		'TRoot.$$Tab': String
	},
	validators: {
		'Agent.Name': "@[Error.Required]"
	},
	delegates: {
		tagSettings
	}
}

// SettingsDelegate for TagsControl — opens the shared Tags dictionary,
// scoped to this entity via [For] = 'Agent'.
async function tagSettings(this: TRoot, items: TTagArray) {
	const ctrl = this.$ctrl;
	ctrl.$showDialog('/catalog/tag/settings', null, { For: 'Agent' });
}

export default template;
