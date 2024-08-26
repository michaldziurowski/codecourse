import fs from "fs"
import express from "express"
import http from "http"
import https from "https"
import cors from "cors"
import bodyParser from "body-parser"
import CodeExecution from "./code-execution"

const app = express!
const httpPort = process.env.PORT or "8000"
const httpsPort = process.env.HTTPS_PORT or "8443"

app.use(cors!)
app.use(bodyParser.json!)

const codeExecutions = {}
	
app.get "/health" do(req,res)
	res.sendStatus(200)

app.post "/run/:runId" do(req, res)
	const data = req.body
	const runId = req.params.runId
	const codeExecution = new CodeExecution runId, data.content
	codeExecutions[runId] = codeExecution 

	codeExecution.store!

	res.sendStatus(201)
		
app.post "/run/:runId/output" do(req, res)
	codeExecutions[req.params.runId].addOutput JSON.stringify req.body
	res.sendStatus(201)

app.get "/run/:runId/output" do(req,res)
	let cleanupTimeoutId
	const runId = req.params.runId

	const clb = do
		clearTimeout cleanupTimeoutId
		res.json codeExecutions[runId].outputs 
		delete codeExecutions[runId]

	cleanupTimeoutId = setTimeout(&, 4000) do
		delete codeExecutions[runId]
		res.json ["Sorry something went wrong...
		It might mean that your code did not build correctly."]
	
	codeExecutions[runId].addCompletedListener clb



const privateKey  = fs.readFileSync("./cert/private.key", "utf8");
const certificate = fs.readFileSync("./cert/certificate.crt", "utf8");

const httpServer = http.createServer(app)
const httpsServer = https.createServer({key:privateKey, cert:certificate}, app)

httpServer.listen(httpPort)
httpsServer.listen(httpsPort)