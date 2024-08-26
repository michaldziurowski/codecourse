import { 
	CODE_CHANGE_INSERT,
	CODE_CHANGE_BACKSPACE,
	CODE_CHANGE_PASTE, 
	CODE_CHANGE_SELECTION,
	EditorChange,
	} from "./models.imba"

import {serverApi} from "./api"

tag RecorderContainer
	def onEditorChange e
		const change = e.detail
		await serverApi.postChange route.params.courseId,change

	css .recorder
		w:100%
		h:100vh

	<self>
		<Recorder.recorder @editorChange=onEditorChange>

tag Recorder
	firstChangeAbsoluteTime = 0
	content = ""

	def awaken
		hackishHandlingOfTab!

	def hackishHandlingOfTab
		$textarea.addEventListener("keydown", do(e)
			if e.code === "Tab"
				e.preventDefault()
				const idx = $textarea.selectionStart
				content = content.slice(0, idx) + "\t" + content.slice(idx)
				imba.commit!
				setTimeout(&, 1) do
					$textarea.focus!
					$textarea.setSelectionRange idx+1,idx+1
		)

	def emitChange kind,changeData
		const now = Date.now!
		let changeTime = 0

		if firstChangeAbsoluteTime === 0
			firstChangeAbsoluteTime = now
		else
			changeTime = now - firstChangeAbsoluteTime
		
		let change = new EditorChange kind, changeTime, changeData

		emit("editorChange", change)

	def onInput e
		if e.inputType === "insertText"
			if e.data
				emitChange CODE_CHANGE_INSERT, {txt: e.data, idx: e.target.selectionStart}
			else
				emitChange CODE_CHANGE_INSERT, {txt: "\n", idx: e.target.selectionStart}
		
		if e.inputType === "insertLineBreak"
			emitChange CODE_CHANGE_INSERT, {txt: "\n", idx: e.target.selectionStart}
		
		if e.inputType === "deleteContentBackward"
			emitChange CODE_CHANGE_BACKSPACE, {idx: e.target.selectionStart}
	
	def onPaste e
		emitChange CODE_CHANGE_PASTE, {txt: e.clipboardData.getData("text"), idx: e.target.selectionStart}

	def onMouseUp e
		if e.target.localName !== "textarea" or !e.target.selectionDirection or e.target.selectionStart === e.target.selectionEnd
			return
		
		emitChange CODE_CHANGE_SELECTION, {start: e.target.selectionStart, end: e.target.selectionEnd, direction: e.target.selectionDirection}
		
	css textarea
		w:100%
		h:100%
		p:10px
		bg:cooler8
		d:block
		c:warm3
		bd:none
		ol:none
		box-sizing:border-box
		bxs:none
		resize:none
		tab-size:4

	<self>
		<textarea$textarea @input=onInput @paste=onPaste @mouseup=onMouseUp spellcheck=false bind=content>

export default RecorderContainer