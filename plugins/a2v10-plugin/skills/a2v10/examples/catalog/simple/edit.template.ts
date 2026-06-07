import { TRoot, TSample } from "./edit";

const template: Template = {
	validators: {
		'Sample.Name': "@[Error.Required]"
	}
}

export default template;
