import { TRate, TRateArray, TRoot } from "./index"

const template: Template = {
	commands: {
		load
	}
};

export default template;

// The clr command is invoked like any other: by name, with an args object, at the endpoint path.
// Whatever InvokeAsync returns arrives here as the resolved value.
async function load() {
	const ctrl: IController = this.$ctrl;
	await ctrl.$invoke('load', {}, '/catalog/currencyrate');
	ctrl.$requery();
}
