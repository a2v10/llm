import { TRoot, TAttachment } from "./index";

const template: Template = {
	commands: {
		upload,
		remove
	}
}

export default template;

// the platform uploads and links; what to do with the new row is the application's
async function upload(this: TRoot) {
	const result = await this.$ctrl.$uploadBlob('/attachment/upload', null, this.Owner);
	if (!result)
		return;
	const row = this.Attachments.$append(result);
	row.$select();
}

// the platform checks exactly the Base the procedure receives
async function remove(this: TRoot, row: TAttachment) {
	if (!row)
		return;
	await this.$ctrl.$invoke('delete', { Id: row.Id, Base: this.Owner.Base, Owner: this.Owner.Id });
	row.$remove();
}
