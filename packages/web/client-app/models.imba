export const CODE_CHANGE_INSERT = "insert"
export const CODE_CHANGE_BACKSPACE = "backspace"
export const CODE_CHANGE_PASTE = "paste"
export const CODE_CHANGE_SELECTION = "selection"

export class EditorChange
	constructor kind,time,data
		kind = kind
		time = time
		data = data
