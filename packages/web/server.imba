import express from "express"
import bodyParser from "body-parser"
import index from "./index.html"
import db from "./db"

const app = express!
const port = process.env.PORT or "8080"

app.use(bodyParser.json())

app.use(express.static("assets"))

app.get "/course/:courseId/changes", do(req, res)
	const courseId = req.params.courseId
	const editorChanges = db.getChanges courseId

	if !editorChanges.length
		res.sendStatus(404)
		return

	res.status(200).json editorChanges

app.post "/course/:courseId/change", do(req, res)
	const courseId = req.params.courseId
	const change = req.body

	db.addChange courseId, change

	res.sendStatus(201)

app.use do(req, res, next)
	res.status(200).send index.body

imba.serve app.listen(port)