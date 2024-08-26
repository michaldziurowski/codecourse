import {
	CODE_CHANGE_INSERT,
	CODE_CHANGE_BACKSPACE,
	CODE_CHANGE_PASTE, 
	CODE_CHANGE_SELECTION,
} from "./models"
import Timer from "./timer"
import {serverApi, connectorApi} from "./api"

tag CourseViewerContainer
	healthy = true
	timer
	changes
	codeContent = ""
	builderOutput = []
	healthCheckIntervalId

	def routed
		changes = await serverApi.getChanges route.params.courseId

		if changes.length	
			timer = new Timer changes.at(-1).time
		else
			timer = new Timer 0

		healthCheckIntervalId = setInterval(&,1000) do
			const prevHealthy = healthy
			healthy = await connectorApi.healthCheck!
			if prevHealthy !== healthy
				imba.commit!
	
	def unmount
		clearInterval healthCheckIntervalId
	
	def onRefreshConsoleClicked 
		let runId = (Math.random() + 1).toString(36).substring(7)
		await connectorApi.postContentToRun runId,codeContent
		builderOutput = await connectorApi.getRunOutput runId
		imba.commit!
	
	css .console-view
		pos:absolute
		t:10px
		r:10px
		w:500px
		h:300px 

	css .progress-panel
		pos:absolute 
		b:0 
		w:100% 
		m:auto
	
	css .code-area
		w:100%
		h:calc(100vh - 70px)

	css .system-unhealthy
		pos:absolute
		t:50%
		l:50%
		transform: translate(-50%,-50%)

	<self>
		<div>
			if healthy
				<ConsoleView.console-view @refreshConsoleClicked=onRefreshConsoleClicked lines=builderOutput>
				<CodeArea.code-area timer=timer changes=changes bind:content=codeContent>
				<ProgressPanel.progress-panel timer=timer>
			else
				<SystemUnhealthyInfo.system-unhealthy>

tag CodeArea
	timer
	changes
	content = ""
	lastPaintedIdx = -1

	def awaken
		timer.onRun onRun.bind(self)
		timer.onTick print.bind(self)
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

	def buildContentUntil time
		for change,idx in changes when idx > lastPaintedIdx and change.time < time
			if change.kind === CODE_CHANGE_INSERT	
				content = content.slice(0, change.data.idx - 1) + change.data.txt + content.slice(change.data.idx - 1)
			elif change.kind === CODE_CHANGE_BACKSPACE
				content = content.slice(0, change.data.idx) + content.slice(change.data.idx+1)
			elif change.kind === CODE_CHANGE_PASTE
				content = content.slice(0, change.data.idx) + change.data.txt + content.slice(change.data.idx)
			elif change.kind === CODE_CHANGE_SELECTION
				$textarea.focus!
				$textarea.setSelectionRange(change.data.start, change.data.end, change.data.direction)

			lastPaintedIdx = idx
	
	def onRun 
		content = ""	
		lastPaintedIdx = -1

	def print elapsed
		const userMovedBack = lastPaintedIdx > -1 and elapsed < changes[lastPaintedIdx].time
		if userMovedBack 
			lastPaintedIdx = -1
			content = ""

		buildContentUntil elapsed	
		imba.commit!
		$textarea.scrollTop = $textarea.scrollHeight

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
		<textarea$textarea bind=content spellcheck=false>

tag ConsoleView
	lines = []

	def build
		x = y = 0

	def onRefreshConsoleClicked
		lines = ["Waiting..."]
		emit("refreshConsoleClicked")

	css
		bg:black
		rd:lg
		c:white
		p:5px
		@hover cursor:move

	css button
		d:block
		bg:black
		bd:none
		cursor:pointer

	css svg
		w:20px
		h:20px
		fill:warm3
	
	css div
		pt:5px
		ff:monospace	

	<self [x:{x} y:{y}] @touch.moved.sync(self)>
		<button @click=onRefreshConsoleClicked>
			<svg src="./reload.svg">
		for output in lines
			<div> output


tag ProgressPanel
	timer
	rangePosition = 0

	def awaken
		timer.onTick changeRangePosition.bind(self)

	def changeRangePosition elapsed,duration
		let newRangePosition = Math.round ((elapsed/duration)*100) 
		if newRangePosition !== rangePosition
			rangePosition = newRangePosition
			imba.commit!

	def onRangeInput e
		timer.moveToPercentage e.target.value 
	
	def onPlayPauseClicked e
		let playing = e.detail
		if playing
			timer.run!
		else
			timer.pause!

	css .container
		d:flex 
		fld:column 
		jc:center

	css .range-container
		d:flex 
		jc:center

	css .buttons-container
		d:flex
		jc:center

	css .range-input
		w:100%
	
	<self @playPauseClicked=onPlayPauseClicked>
		<div.container>
			<div.range-container>
				<input.range-input type="range" bind=rangePosition @input=onRangeInput>
			<div.buttons-container>
				<PlayPauseButton>

tag PlayPauseButton
	playSvg = import("./play.svg")
	pauseSvg = import("./pause.svg")
	playing = false

	def toggle
		playing = !playing
		emit("playPauseClicked", playing)

	css button
		bg:none
		bd:none
		cursor:pointer
		p:5px

	css svg
		w:35px
		h:35px
		fill:warm3

	<self>
		<button @click=toggle>
			<svg src=(playing ? pauseSvg : playSvg)>

tag SystemUnhealthyInfo 
	css .info
		bg: orange3
		rd: md
		p: 10px
		ff: monospace

	css code
		bg:black
		c:white
		p:0 7px
		rd:md

	<self>
		<div.info> 
			<p> "Yikes! it seems that you have not yet configured course environment." 
			<p> "Please follow those steps" 
				<ol>
					<li> "Create new course directory"
					<li> "Download docker compose configuration file from {<a href="{serverApi.baseUrl}/compose.yaml" download="compose.yaml"> "here"} and place it in course directory"
					<li> "In course directory run {<code> "docker compose up -d"}"
					<li> "Once the environment will be build this message will disapear"

export default CourseViewerContainer