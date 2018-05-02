#
#Generate Random ID with 4 Digits
#Insert Data into DB with Payload
#
#Sample JSON Documents
mongo = require 'mongodb'
MongoClient = mongo.MongoClient
url = process.env.MONGO_DB_URL || 'mongodb://34.203.13.40:27017/hubot'
mongocollection=process.env.MONGO_COLL || 'ticketgenerator'

console.log(db)
db=MongoClient.connect url, (err, conn) ->
	if err
		console.log 'Unable to connect . Error:', err
	else
		console.log 'Connection established to', url
		db=conn

		
		
		
		
module.exports =
	getNextSequence: (callback)->
		
		col = db.collection('counters')
		tckid=col.findAndModify { _id: 'ticketIdGenerator'}, [],{ $inc: seq: 1 }, {}, (err, object) ->
			console.log('inside func')
			if err
				console.log("error: "+err)
				callback err,null
			else
				console.log object.value.seq
				callback null,object.value.seq
	add_in_mongo: (doc1) ->
		console.log(doc1)
		
		col = db.collection(mongocollection)
		col.insert [doc1], (err, result) ->
			if err
				console.log err
			else
				console.log result
				console.log "updated counter"
				#result                                                


  

#console.log("check::"+check)
#update=insert_data check
#console.log(update)