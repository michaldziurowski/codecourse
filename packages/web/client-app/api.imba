class HttpApi
	constructor baseUrl
		baseUrl = baseUrl

	def post path,data
		const callHeaders = new Headers;
		callHeaders.append("Content-Type", "application/json");

		return window.fetch "{baseUrl}{path}", {method: "POST",body: (JSON.stringify data), headers: callHeaders};
	
	def get path
		return window.fetch "{baseUrl}{path}"


class ConnectorApi < HttpApi
	def healthCheck
		try
			const res = await get "/health"
			return res.ok
		catch e
			return false


	def postContentToRun runId,content
		return post "/run/{runId}", {content}
	
	def getRunOutput runId
		const res = await get "/run/{runId}/output"
		return res.json! 

class ServerApi < HttpApi
	def getChanges courseId
		const res = await get "/course/{courseId}/changes"
		return res.json!
	
	def postChange courseId,change
		return post "/course/{courseId}/change",change

export const connectorApi = new ConnectorApi process.env.CONNECTOR_URL or "https://connector.mdztmp.pl:5413"
export const serverApi = new ServerApi process.env.SERVER_URL or "https://mdztmp.pl"

