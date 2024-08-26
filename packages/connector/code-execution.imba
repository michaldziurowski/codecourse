import fs from "fs"

class CodeExecution
	completedListener
	outputs = []

	constructor runId, code
		runId = runId
		code = code
		const outputReqex = /console\.log/g
		const matches = code.match outputReqex
		expectedOutputsCount = (matches or []).length

	def addOutput output
		outputs.push(output)

		if outputs.length === expectedOutputsCount and completedListener
			completedListener!

	def addCompletedListener clb
		if outputs.length === expectedOutputsCount
			clb!
			return
		
		completedListener = clb

	def store
		const codeToStore = ` 
const oldCL = console.log
console.log = do()
	const args = [...arguments]
	oldCL(...args)
	const callHeaders = new Headers()
	callHeaders.append(\"Content-Type\", \"application/json\")
	await fetch(\"http://connector:8000/run/{runId}/output\", \{method: \"POST\",body: (JSON.stringify args), headers: callHeaders\})
{code}`

		const storeClb = do(err)
			if err
				return console.log err

		fs.writeFile "./data/index.imba", codeToStore, storeClb
	
export default CodeExecution