class Timer
	elapsed = 0
	paused = false
	lastPaint = 0
	rafId=0
	tickCallbacks = []
	runCallbacks = []

	constructor duration
		duration = duration

	def onTick clb
		tickCallbacks.push clb
	
	def onRun clb
		runCallbacks.push clb

	def run 
		for clb in runCallbacks
			clb!

		const paint = do
			const now = Date.now!

			# first run
			if lastPaint === 0
				lastPaint = now

			# first run after pause
			if paused
				paused = false
				lastPaint = now
			
			elapsed = elapsed + now - lastPaint

			for clb in tickCallbacks
				clb elapsed,duration

			lastPaint = now

			if elapsed <= duration
				rafId = window.requestAnimationFrame paint
			else
				elapsed = 0
				lastPaint = 0

		rafId = window.requestAnimationFrame paint
	
	def pause
		paused = true
		window.cancelAnimationFrame rafId
	

	def moveToPercentage perc
		elapsed = Math.round duration*(perc/100)

		lastPaint = Date.now!

export default Timer