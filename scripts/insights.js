var request = require("request");
var exec = require('child_process').exec;
//Function to change the status of issue with parameters url,username,password,issue_key,status
var test_call = function (nexus_url, nexus_user_id, nexus_password, repo, callback){

url=nexus_url+'/nexus/service/local/lucene/search?g='+repo+''


console.log(url)
var options = {
		auth: {
		'user': nexus_user_id,
		'pass': nexus_password
		},
		method: 'GET',
		url: url,
		
		}
request(options, function (error, response, body) {
	if(error){
		console.log(error)
		callback(error,null,null)
	}
	if(response.statusCode==200){

result = body.split('<artifact>')
			if(result.length==1){
				dt = 'No artifacts found for groupId: '+repo
				console.log(dt);
				}
			else{

				
				console.log(result[1].split('<groupId>')[1].split('</groupId>')[0])
				console.log(result[1].split('<artifactId>')[1].split('</artifactId>')[0])
				console.log(result[1].split('<version>')[1].split('</version>')[0])
				//dt = '*No.*\t\t\t*Group Id*\t\t\t*Artifact Id*\t\t\t*Version*\t\t\t*Repo Id*\n'
				
				var count=1;
				var cmd;
				var pack;
				var slackattchment;
				for (var i=1;i<result.length;i++){
					
					if(result[i].split('<artifactId>')[1].split('</artifactId>')[0]=='PlatformInsights' || result[i].split('<artifactId>')[1].split('</artifactId>')[0]=='PlatformUI2.0' ||result[i].split('<artifactId>')[1].split('</artifactId>')[0]=='PlatformService' || result[i].split('<artifactId>')[1].split('</artifactId>')[0]=='PlatformEngine' ){
						
						//dt = dt + count+'\t\t\t'+result[i].split('<groupId>')[1].split('</groupId>')[0]+'\t\t\t'+result[i].split('<artifactId>')[1].split('</artifactId>')[0]+'\t\t\t'+result[i].split('<version>')[1].split('</version>')[0]+'\n'+'\t\t\t'+result[i].split('<latestSnapshotRepositoryId>')[1].split('</latestSnapshotRepositoryId>')[0]+'\n'
						count++;
						
						
						if(result[i].split('<artifactId>')[1].split('</artifactId>')[0]=='PlatformService'){pack="war"}
						else if(result[i].split('<artifactId>')[1].split('</artifactId>')[0]=='PlatformInsights' || result[i].split('<artifactId>')[1].split('</artifactId>')[0]=='PlatformEngine'){pack="jar"}
						else{pack="zip"}
						//cmd="curl -X GET "+nexus_url+"/nexus/content/repositories/"+result[i].split('<latestSnapshotRepositoryId>')[1].split('</latestSnapshotRepositoryId>')[0]+"/com/cognizant/devops/"+result[i].split('<artifactId>')[1].split('</artifactId>')[0]+"/"+result[i].split('<version>')[1].split('</version>')[0]+"/ | grep -Eo '<a href.*(</a>)' | grep -o '[^>]*"+pack+"' | tr -d '' | sed 's/.*"+"\\"+"///'";
						
						cmd="curl -s -X GET "+nexus_url+"/nexus/content/repositories/"+result[i].split('<latestSnapshotRepositoryId>')[1].split('</latestSnapshotRepositoryId>')[0]+"/com/cognizant/devops/"+result[i].split('<artifactId>')[1].split('</artifactId>')[0]+"/"+result[i].split('<version>')[1].split('</version>')[0]+"/ | grep -o '<a .*href=.*>' | sed -e 's/<a /\\n<a /g' | sed -e 's/<a .*href=['"+"\"'"+"\"'"+"\""+"]//' -e 's/["+"\"'"+"\"'"+"\"'"+"].*$//' -e '/^$/ d' | grep '.*\."+pack+"$' | sed 's/.*\\///'"
						
						
						
						
						
						
						
						

							exec(cmd, (err, stdout, stderr) => {
							  if (err) {
								console.error(err);
								return;
							  }
							  
							  
							  if(stdout!=''){
							  var dt='';
							  var tmp=stdout.split("-");
							  dt+="*"+tmp[0]+"*\n"+stdout;
							  console.log(stderr);
							  console.log(dt)
							  callback(null,dt,null)
							  }
							});
						}
						
						
						
						}
						
						
						
						
						
					
					
//+'\t\t\t'+result[i].split('<latestSnapshotRepositoryId>')[1].split('</latestSnapshotRepositoryId>')[0]+'\n'
				}
				
				
			}
	
	else{
		console.log(body)
		callback(null,null,"error in getting artifacts")
	}
});
	
				
					
}

module.exports = {
  test_call: test_call	// MAIN FUNCTION
  
}

//test_call("http://54.172.37.182:8081","admin","admin123","com.cognizant.devops");
