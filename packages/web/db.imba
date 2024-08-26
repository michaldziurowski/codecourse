import Sqlite from "better-sqlite3"

class DB
	db
	constructor
		db = new Sqlite "./data/editor_changes.db"
		db.pragma "journal_mode = WAL"

	def init
		db.exec("CREATE TABLE IF NOT EXISTS editor_changes (
    				courseId TEXT,
					kind TEXT,
					time INTEGER,
					data TEXT
				);")
	
	def addChange courseId, change
		const stmt = db.prepare "INSERT INTO editor_changes (courseId, kind, time, data) VALUES (?,?,?,?)"
		stmt.run courseId, change.kind, change.time, JSON.stringify(change.data)
	
	def getChanges courseId
		const stmt = db.prepare "SELECT kind, time, data FROM editor_changes WHERE courseId = ? ORDER BY time ASC"
		const editorChanges = stmt.all courseId

		const changesMapper = do(c)
			return {kind:c.kind, time:c.time, data:JSON.parse(c.data)}

		return editorChanges.map changesMapper

const db = new DB
db.init!

export default db