#Add Comment: add comment <comment> to jira issue <project_id>
#Update Summary: update summary of issue <project_id> as <summary>


#Environment Variable Required
#   HUBOT_JIRA_URL
#   HUBOT_JIRA_USER
#   HUBOT_JIRA_PASSWORD


botname = process.env.HUBOT_NAME
# Load Dependencies
exec = require('child_process').exec
eindex = require('../node_modules/hubot-elasticsearch-logger/index')
wallData = require('../node_modules/hubot-elasticsearch-logger/index');
node_ssh = require('node-ssh')
fs = require("fs");
test=require('./insights.js');
nexus_url=process.env.NEXUS_URL
nexus_user_id=process.env.NEXUS_USERNAME
nexus_password=process.env.NEXUS_PASSWORD
repo='com.cognizant.devops'
ssh = new node_ssh()
module.exports = (robot) ->
	robot.respond /list artifacts/i, (msg) ->
		test.test_call nexus_url, nexus_user_id, nexus_password, repo, (error, stdout, stderr) ->
			if error
		
				console.log(error)
				msg.send "Error occured while listing artifacts";
			if stderr
		
				console.log(stderr)
				msg.send stderr;
			if stdout
				console.log(stdout)
				msg.send stdout;
	robot.respond /help/i, (msg) ->
		msg.send "To list artifacts of repositories --> *list artifacts* \n To deploy artifact to an environment --> deploy <artifactName> <environment> (Ex: *deploy myartifact.ext <qa or qaSpark or prod or prodSpark>*)\nTo list release versions in docroot  --> *list docrootRelease versions*\nTo deploy artifact to docroot server on demand --> *deploy <artifactName> <environment>* (Ex. *deploy artifact.ext docrootOndemand* )\nTo deploy a release to docroot server --> *deploy <artifactName> docrootRelease <version>* (Ex. *deploy artifact.ext docrootRelease v9.0*)\nTo deploy PlatformAgent to docroot --> *deploy agentzip docrootOndemand* \n *deploy <agentzip/agentfolder> docrootRelease <version>*\nTo deploy PlatformIndividualAgents zip file to docroot --> *deploy PlatformIndividualAgents docrootRelease <version>* \n To deploy Latest Artifacts to docroot --> *deploy <PlatformService/PlatformEngine/PlatformUI/PlatformInsights/agentzip> docrootReleaseLatest <version>*"
	robot.respond /list docrootRelease versions/i, (msg) ->
		pemfile='./FARM-124-dce49fa0.us-east-1.pem'
		host=process.env.DOC_ROOT_ENV
		username='ec2-user'
		ssh.connect(
			host: host
			username: username
			privateKey: pemfile).then (->
				ssh.execCommand('ls /var/www/html/insights_install/release/').then (result) ->
					console.log(result)
					if(result.stderr!='')
				        msg.send stderr
					if(result.stdout!='')
						msg.send result.stdout
					else
						msg.send 'no version found'
				    
			)
	robot.respond /deploy\s+(\S+)\s+(\S+)$/i, (msg) ->
		if(msg.match[1]=='agentzip')
			console.log("into agent")
			host=''
			pemfile=''
			username=''
			host=process.env.DOC_ROOT_ENV
			pemfile='./FARM-124-dce49fa0.us-east-1.pem'
			username='ec2-user'
			ssh.connect(
				host: host
				username: username
				privateKey: pemfile).then (->
					console.log('ssh connected agent')
					ssh.execCommand('date +"%d-%m-%Y"').then (result) ->
						console.log("date::"+result.stdout)
						nextdir=result.stdout
						if(result.stderr=='')
							
							ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/'+nextdir+'/agents').then (result) ->
								if(result.stdout=='')
									ssh.execCommand('sudo wget -O /var/www/html/insights_install/'+nextdir+'/agents/agent.zip https://github.com/CognizantOneDevOps/Insights/archive/master.zip').then (result) ->
										console.log(result)
										if(result.stdout=='')
																		
											if(result.stderr.indexOf("ERROR")==-1)
												ssh.execCommand('sudo unzip -o /var/www/html/insights_install/'+nextdir+'/agents/agent.zip'+' -d /var/www/html/insights_install/'+nextdir+'/agents').then (result2) ->
													console.log("unzip done::: ")
													console.log(result2)
													if(result2.stderr=='')
														
														ssh.execCommand('sudo rm -rf /var/www/html/insights_install'+'/'+nextdir+'/agents/PlatformAgents').then (result) ->
															console.log("result ::: "+result)
															console.log(result)
															if(result.stdout=='')
																ssh.execCommand('sudo mv /var/www/html/insights_install/'+nextdir+'/agents/Insights-master/PlatformAgents /var/www/html/insights_install/'+nextdir+'/agents/PlatformAgents').then (result) ->
																	console.log("result ::: "+result)
																	console.log(result)
																	if(result.stdout=='')
																		console.log("moved folders")
																		ssh.execCommand('cd /var/www/html/insights_install/'+nextdir+'/agents/PlatformAgents/; sudo rm -rf src test pom.xml .gitignore').then (result) ->
																			console.log("removed extra folder")
																			console.log(result)
																			if(result.stdout=='')
																				ssh.execCommand('cd /var/www/html/insights_install/'+nextdir+'/agents/; sudo zip -r PlatformAgents.zip PlatformAgents').then (result) ->
																					console.log("ziped folder")
																					console.log(result)
																					if(result.stdout.indexOf("ERROR")==-1)
																						msg.send "agent is deployed to docroot successfully"
																					else
																						msg.send "Error ocuured while deploying \n"+result2.stdout+'\n'+result2.stderr
																					ssh.execCommand('sudo rm -rf /var/www/html/insights_install'+'/'+nextdir+'/agents/Insights-master /var/www/html/insights_install'+'/'+nextdir+'/agents/agent.zip /var/www/html/insights_install'+'/'+nextdir+'/agents/PlatformAgents').then (result) ->
																						console.log("result ::: "+result)
																						console.log(result)
																						if(result.stdout=='')
																							console.log("removed folders")
																					
													else
														msg.send "Error ocuured while deploying \n"+result2.stderr
											else
												msg.send "Error occured while downloading \n"+result1.stderr
				),(error) ->
						console.log('error in ssh :: '+error)
						msg.send 'Error connecting '+envi+"\n"+error
			console.log("listen to command")
		else
			envi=msg.match[2]
			artifact=msg.match[1]
			tmp=artifact.split("-")
			branch=tmp[0]
			version=tmp[1]+"-SNAPSHOT"
			dirtmp=tmp[2].split(".")
			dir=dirtmp[0]
			yy=dir.substr(0, 4)
			mm=dir.substr(4, 2)
			dd=dir.substr(6)
			datedir=dd+'-'+mm+'-'+yy
			console.log(branch)
			console.log(version)
			console.log(artifact)
			#branch=msg.match[4]
			#version=msg.match[2]
			host=''
			pemfile=''
			username=''
			
			#selecting pem file
			if(envi == 'qa' || envi == 'prod' || envi == 'qaSpark'|| envi=='prodSpark')
				pemfile='./FARM-391-dce49fa0.us-east-1.pem'
			else
				pemfile='./FARM-124-dce49fa0.us-east-1.pem'
					
			#selecting username
			if(envi == 'qaSpark'|| envi=='prodSpark')#&& artifact.indexOf(".jar")!=-1)
				username='ubuntu' 
			else
				username='ec2-user'
			
			#selecting host
			if(envi == 'qa' )#&& artifact.indexOf(".jar")==-1)
				host=process.env.QA_ENV
			else if(envi.indexOf('docroot')!=-1)
				host=process.env.DOC_ROOT_ENV
			else if(envi == 'qaSpark')#  && artifact.indexOf(".jar")!=-1)
				host=process.env.QA_SPARK_ENV
			else if(envi == 'prod'  )#&& artifact.indexOf(".jar")==-1)
				host=process.env.PROD_ENV 
			else if(envi == 'prodSpark')#  && artifact.indexOf(".jar")!=-1)
				host=process.env.PROD_SPARK_ENV
				
			#printing to check
			console.log(envi)
			console.log(host)
			console.log(username)
			console.log(pemfile)
			
			#ssh connection to environments
			ssh.connect(
				host: host
				username: username
				privateKey: pemfile).then (->
					console.log('ssh connected')
					if(envi == 'qa' || envi == 'qaSpark')
						if (branch=='PlatformService')
							ssh.execCommand('sudo rm -rf /var/lib/tomcat/webapps/PlatformService /var/lib/tomcat/webapps/PlatformService.war').then (result) ->
								console.log("result ::: "+result)
								console.log(result)
								if(result.stdout=='')
									console.log("removed folders")
							ssh.execCommand('sudo service tomcat stop').then (result) ->
								console.log("result ::: "+result)
								console.log(result)
								if(result.stdout=='')
									
									ssh.execCommand('wget -O /var/lib/tomcat/webapps/PlatformService.war '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
										console.log("result wget :: ")
										console.log(result1)
										if(result1.stdout=='')
											console.log(result1.stderr.indexOf("ERROR"))
											console.log(result1.stderr.indexOf("http"))
											if(result1.stderr.indexOf("ERROR")!=-1)
												msg.send "Error occured while downloading \n"+result1.stderr
												ssh.execCommand('sudo service tomcat start').then (result2) ->
													console.log("result start::: ")
													console.log(result2)
													
								
									
											else
												ssh.execCommand('sudo service tomcat start').then (result2) ->
													console.log("result start::: ")
													console.log(result2)
													if(result2.stdout=='')
														msg.send artifact+" is deployed to "+envi+" successfully"
						else if(branch=='PlatformUI2.0')
							ssh.execCommand('sudo service tomcat stop').then (result) ->
								console.log("result stop::: "+result)
								console.log(result)
								if(result.stdout=='')
									
									ssh.execCommand('wget -O /tmp/PlatformUI2.0.zip '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
										console.log("result wget :: ")
										console.log(result1)
										if(result1.stdout=='')
											
											if(result1.stderr.indexOf("ERROR")==-1)
												ssh.execCommand('unzip -o /tmp/PlatformUI2.0.zip -d /var/lib/tomcat/webapps/').then (result2) ->
													console.log("unzip done::: ")
													console.log(result2)
													if(result2.stderr=='')
														
														ssh.execCommand('sudo service tomcat start').then (result3) ->
															console.log("result start::: ")
															console.log(result3)
															if(result3.stdout=='')
																msg.send artifact+" is deployed to "+envi+" successfully"
													else
														msg.send "Error ocuured while deploying \n"+result2.stderr
											else
												ssh.execCommand('sudo service tomcat start').then (result3) ->
													console.log("result start::: ")
													console.log(result3)
													msg.send result1.stderr
						#if (envi=='qaSpark')
						else if(branch=='PlatformInsights')
							
							console.log("inside insights")	
							ssh.execCommand('sudo wget -O /opt/PlatformInsights-jar/PlatformInsights-'+version+'-jar-with-dependencies.jar '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
								console.log("result wget :: ")
								console.log(result1)
								if(result1.stdout=='')
									if(result1.stderr.indexOf("ERROR")==-1)
										ssh.execCommand('sudo ps -ef | grep /opt/PlatformInsights-jar/PlatformInsights-'+version+'-jar-with-dependencies.jar | cut -c 10-15 | xargs kill -9  | exit 0').then (result2) ->
											console.log("unzip done::: ")
											console.log(result2)
											if(result2.stdout=='')
												
												ssh.execCommand('sudo chmod +x /opt/PlatformInsights-jar/PlatformInsights-'+version+'-jar-with-dependencies.jar').then (result3) ->
													console.log("result start::: ")
													console.log(result3)
													if(result3.stdout=='')
														ssh.execCommand('nohup java -jar /opt/PlatformInsights-jar/PlatformInsights-'+version+'-jar-with-dependencies.jar > /opt/PlatformInsights-jar/nohup.out 2>&1 &').then (result3) ->
															console.log("result start::: ")
															console.log(result3)
															if(result3.stdout=='')
																msg.send artifact+" is deployed to "+envi+" successfully"
									else
										msg.send "Error ocuured while deploying \n"+result1.stderr
						#if(envi!='qaSpark')
						else if(branch=='PlatformEngine')
							
							console.log("inside engine")		
							ssh.execCommand('wget -O /opt/insightsengine/PlatformEngine.jar '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
								console.log("result wget :: ")
								console.log(result1)
								if(result1.stdout=='')
									if(result1.stderr.indexOf("ERROR")==-1)
										ssh.execCommand('ps -ef | grep /opt/insightsengine/PlatformEngine.jar | cut -c 10-15 | xargs kill -9  | exit 0').then (result2) ->
											console.log("unzip done::: ")
											console.log(result2)
											if(result2.stdout=='')
												
												ssh.execCommand('chmod +x /opt/insightsengine/PlatformEngine.jar').then (result3) ->
													console.log("result start::: ")
													console.log(result3)
													if(result3.stdout=='')
														ssh.execCommand('nohup java -jar /opt/insightsengine/PlatformEngine.jar > /opt/insightsengine/nohup.out 2>&1 &').then (result3) ->
															console.log("result start::: ")
															console.log(result3)
															if(result3.stdout=='')
																msg.send artifact+" is deployed to "+envi+" successfully"
									else
										msg.send "Error ocuured while deploying \n"+result1.stderr
					else if(envi == 'prod' || envi == 'prodSpark')
						if (branch=='PlatformService')
							ssh.execCommand('sudo rm -rf /var/lib/tomcat/webapps/PlatformService /var/lib/tomcat/webapps/PlatformService.war').then (result) ->
								console.log("result ::: "+result)
								console.log(result)
								if(result.stdout=='')
									console.log("removed folders")
							ssh.execCommand('sudo service tomcat stop').then (result) ->
								console.log("result ::: "+result)
								console.log(result)
								if(result.stdout=='')
									console.log("tomcat stopped")
									chktmp='wget -O /var/lib/tomcat/webapps/PlatformService.war '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact
									console.log(chktmp)
									ssh.execCommand('wget -O /var/lib/tomcat/webapps/PlatformService.war '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
										console.log("result wget :: ")
										console.log(result1)
										if(result1.stdout=='')
											console.log(result1.stderr.indexOf("ERROR"))
											console.log(result1.stderr.indexOf("http"))
											if(result1.stderr.indexOf("ERROR")!=-1)
												msg.send "Error occured while downloading \n"+result1.stderr
												ssh.execCommand('sudo service tomcat start').then (result2) ->
													console.log("result start::: ")
													console.log(result2)
													
								
									
											else
												ssh.execCommand('sudo service tomcat start').then (result2) ->
													console.log("result start::: ")
													console.log(result2)
													if(result2.stdout=='')
														msg.send artifact+" is deployed to "+envi+" successfully"
						else if(branch=='PlatformUI2.0')
							ssh.execCommand('sudo service tomcat stop').then (result) ->
								console.log("result stop::: "+result)
								console.log(result)
								if(result.stdout=='')
									
									ssh.execCommand('wget -O /tmp/PlatformUI2.0.zip '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
										console.log("result wget :: ")
										console.log(result1)
										if(result1.stdout=='')
											
											if(result1.stderr.indexOf("ERROR")==-1)
												ssh.execCommand('unzip -o /tmp/PlatformUI2.0.zip -d /var/lib/tomcat/webapps/').then (result2) ->
													console.log("unzip done::: ")
													console.log(result2)
													if(result2.stderr=='')
														
														ssh.execCommand('sudo service tomcat start').then (result3) ->
															console.log("result start::: ")
															console.log(result3)
															if(result3.stdout=='')
																msg.send artifact+" is deployed to "+envi+" successfully"
													else
														msg.send "Error ocuured while deploying \n"+result2.stderr
											else
												ssh.execCommand('sudo service tomcat start').then (result3) ->
													console.log("result start::: ")
													console.log(result3)
													msg.send result1.stderr
						#if(envi=='prodSpark')
						else if(branch=='PlatformInsights')
							
									
							ssh.execCommand('sudo wget -O /opt/PlatformInsights-jar/PlatformInsights-'+version+'-jar-with-dependencies.jar '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
								console.log("result wget :: ")
								console.log(result1)
								if(result1.stdout=='')
									if(result1.stderr.indexOf("ERROR")==-1)
										ssh.execCommand('sudo ps -ef | grep /opt/PlatformInsights-jar/*-jar-with-dependencies.jar | cut -c 10-15 | xargs kill -9  | exit 0').then (result2) ->
											console.log("unzip done::: ")
											console.log(result2)
											
											if(result2.stdout=='')
												
												ssh.execCommand('sudo chmod +x /opt/PlatformInsights-jar/PlatformInsights-'+version+'-jar-with-dependencies.jar').then (result3) ->
													console.log("result start::: ")
													console.log(result3)
													if(result3.stdout=='')
														ssh.execCommand('nohup java -jar  /opt/PlatformInsights-jar/PlatformInsights-'+version+'-jar-with-dependencies.jar >  /opt/PlatformInsights-jar/nohup.out &').then (result3) ->
															console.log("result start::: ")
															console.log(result3)
															if(result3.stdout=='')
																msg.send artifact+" is deployed to "+envi+" successfully"
									else
										msg.send "Error ocuured while deploying \n"+result1.stderr
						#if(envi!='prodSpark')
						else if(branch=='PlatformEngine')
							
									
							ssh.execCommand('wget -O /opt/insightsengine/PlatformEngine.jar '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
								console.log("result wget :: ")
								console.log(result1)
								if(result1.stdout=='')
									if(result1.stderr.indexOf("ERROR")==-1)
										ssh.execCommand('ps -ef | grep /opt/insightsengine/PlatformEngine.jar | cut -c 10-15 | xargs kill -9  | exit 0').then (result2) ->
											console.log("unzip done::: ")
											console.log(result2)
											if(result2.stdout=='')
												
												ssh.execCommand('chmod +x /opt/insightsengine/PlatformEngine.jar').then (result3) ->
													console.log("result start::: ")
													console.log(result3)
													if(result3.stdout=='')
														ssh.execCommand('nohup java -jar /opt/insightsengine/PlatformEngine.jar > /opt/insightsengine/nohup.out 2>&1 &').then (result3) ->
															console.log("result start::: ")
															console.log(result3)
															if(result3.stdout=='')
																msg.send artifact+" is deployed to "+envi+" successfully"
									else
										msg.send "Error ocuured while deploying \n"+result1.stderr
					else if(envi.indexOf('docroot')!=-1)
						if(envi=='docrootOndemand')
							if (branch=='PlatformService')
								nextdir='serviceWar'
								ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/'+datedir+'/'+nextdir).then (result) ->
									console.log(result)
									if(result.stdout=='')
										
										ssh.execCommand('sudo wget -O /var/www/html/insights_install/'+datedir+'/'+nextdir+'/'+'PlatformService-'+version+'.war '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
											console.log("result wget :: ")
											console.log(result1)
											if(result1.stdout=='')
												console.log(result1.stderr.indexOf("ERROR"))
												console.log(result1.stderr.indexOf("http"))
												if(result1.stderr.indexOf("ERROR")!=-1)
													msg.send "Error occured while downloading \n"+result1.stderr
												else
													msg.send artifact+" is deployed to "+envi+" successfully"
									else
										msg.send result.stderr
								
							else if(branch=='PlatformUI2.0')
								nextdir='uiApp'
								ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/'+datedir+'/'+nextdir).then (result) ->
									console.log(result)
									if(result.stdout=='')
										ssh.execCommand('sudo wget -O /var/www/html/insights_install/'+datedir+'/'+nextdir+'/app.zip '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
											console.log("result wget :: ")
											console.log(result1)
											if(result1.stdout=='')
												
												if(result1.stderr.indexOf("ERROR")==-1)
													msg.send artifact+" is deployed to "+envi+" successfully"
												else
													msg.send "Error occured while downloading \n"+result1.stderr
							else if(branch=='PlatformInsights')
								nextdir='sparkJar'
								ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/'+datedir+'/'+nextdir).then (result) ->
									console.log(result)
									if(result.stdout=='')
										ssh.execCommand('sudo wget -O /var/www/html/insights_install/'+datedir+'/'+nextdir+'/PlatformInsights-'+version+'-jar-with-dependencies.jar '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
											console.log("result wget :: ")
											console.log(result1)
											if(result1.stdout=='')
												if(result1.stderr.indexOf("ERROR")==-1)
													if(result1.stderr.indexOf("ERROR")==-1)
														msg.send artifact+" is deployed to "+envi+" successfully"
													else
														msg.send "Error occured while downloading \n"+result1.stderr
							else if(branch=='PlatformEngine')
								nextdir='engineJar'
								ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/'+datedir+'/'+nextdir).then (result) ->
									console.log(result)
									if(result.stdout=='')
										ssh.execCommand('sudo wget -O /var/www/html/insights_install/'+datedir+'/'+nextdir+'/PlatformEngine-'+version+'.jar '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
											console.log("result wget :: ")
											console.log(result1)
											if(result1.stdout=='')
												if(result1.stderr.indexOf("ERROR")==-1)
													if(result1.stderr.indexOf("ERROR")==-1)
														msg.send artifact+" is deployed to "+envi+" successfully"
													else
														msg.send "Error occured while downloading \n"+result1.stderr
				),(error) ->
						console.log('error in ssh :: '+error)
						msg.send 'Error connecting '+envi+"\n"+error
	robot.respond /deploy\s+(\S+)\s+(\S+)\s+(\S+)$/i, (msg) ->
		envi=msg.match[2]
		artifact=msg.match[1]
		if(artifact!='agent')
			tmp=artifact.split("-")
			branch=tmp[0]
			version=tmp[1]+"-SNAPSHOT"
		versiondir=msg.match[3]
		console.log(branch)
		console.log(version)
		console.log(artifact)
		#branch=msg.match[4]
		#version=msg.match[2]
		host=''
		pemfile=''
		username=''
		if(envi.indexOf('docroot')!=-1)
			host=process.env.DOC_ROOT_ENV
			pemfile='./FARM-124-dce49fa0.us-east-1.pem'
			username='ec2-user'
		#printing to check
		console.log(envi)
		console.log(host)
		console.log(username)
		console.log(versiondir)
		console.log(pemfile)
		
		#ssh connection to environments
		ssh.connect(
			host: host
			username: username
			privateKey: pemfile).then (->
				console.log('ssh connected')
				if(envi=='docrootRelease')
					
					if (branch=='PlatformService')
						nextdir='serviceWar'
						ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/release/'+versiondir+'/'+nextdir).then (result) ->
							console.log(result)
							if(result.stdout=='')
								
								ssh.execCommand('sudo wget -O /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/'+'PlatformService-'+version+'.war '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
									console.log("result wget :: ")
									console.log(result1)
									if(result1.stdout=='')
										console.log(result1.stderr.indexOf("ERROR"))
										console.log(result1.stderr.indexOf("http"))
										if(result1.stderr.indexOf("ERROR")!=-1)
											msg.send "Error occured while downloading \n"+result1.stderr
										else
											msg.send artifact+" is deployed to "+envi+" successfully"
							else
								msg.send result.stderr
						
					else if(branch=='PlatformUI2.0')
						nextdir='uiApp'
						ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/release/'+versiondir+'/'+nextdir).then (result) ->
							console.log(result)
							if(result.stdout=='')
								ssh.execCommand('sudo wget -O /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/app.zip '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
											console.log("result wget :: ")
											console.log(result1)
											if(result1.stdout=='')
												
												if(result1.stderr.indexOf("ERROR")==-1)
													msg.send artifact+" is deployed to "+envi+" successfully"
												else
													msg.send "Error occured while downloading \n"+result1.stderr
					else if(branch=='PlatformInsights')
						nextdir='sparkJar'
						ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/release/'+versiondir+'/'+nextdir).then (result) ->
							console.log(result)
							if(result.stdout=='')
								ssh.execCommand('sudo wget -O /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformInsights-'+version+'-jar-with-dependencies.jar '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
									console.log("result wget :: ")
									console.log(result1)
									if(result1.stdout=='')
										if(result1.stderr.indexOf("ERROR")==-1)
											if(result1.stderr.indexOf("ERROR")==-1)
												msg.send artifact+" is deployed to "+envi+" successfully"
											else
												msg.send "Error occured while downloading \n"+result1.stderr
					else if(branch=='PlatformEngine')
						nextdir='engineJar'
						ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/release/'+versiondir+'/'+nextdir).then (result) ->
							console.log(result)
							if(result.stdout=='')
								ssh.execCommand('sudo wget -O /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformEngine-'+version+'.jar '+process.env.NEXUS_URL+'/nexus/content/repositories/buildonInsights/com/cognizant/devops/'+branch+'/'+version+'/'+artifact).then (result1) ->
									console.log("result wget :: ")
									console.log(result1)
									if(result1.stdout=='')
										if(result1.stderr.indexOf("ERROR")==-1)
											if(result1.stderr.indexOf("ERROR")==-1)
												msg.send artifact+" is deployed to "+envi+" successfully"
											else
												msg.send "Error occured while downloading \n"+result1.stderr
					else if(artifact=='agentzip')
						nextdir='agents'
						ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/release/'+versiondir+'/'+nextdir).then (result) ->
							if(result.stdout=='')
								ssh.execCommand('sudo wget -O /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/agent.zip https://github.com/CognizantOneDevOps/Insights/archive/master.zip').then (result) ->
									console.log(result)
									if(result.stdout=='')
																	
										if(result.stderr.indexOf("ERROR")==-1)
											ssh.execCommand('sudo unzip -o /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/agent.zip'+' -d /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/').then (result2) ->
												console.log("unzip done::: ")
												console.log(result2)
												if(result2.stderr=='')
													
													ssh.execCommand('sudo rm -rf /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformAgents').then (result) ->
														console.log("result ::: "+result)
														console.log(result)
														if(result.stdout=='')
															ssh.execCommand('sudo mv /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/Insights-master/PlatformAgents /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformAgents').then (result) ->
																console.log("result ::: "+result)
																console.log(result)
																if(result.stdout=='')
																	console.log("moved folders")
																	ssh.execCommand('cd /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformAgents/; sudo rm -rf src test pom.xml .gitignore').then (result) ->
																		console.log("removed extra folder")
																		console.log(result)
																		if(result.stdout=='')
																			ssh.execCommand('cd /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/; sudo zip -r PlatformAgents.zip PlatformAgents').then (result) ->
																				console.log("ziped folder")
																				console.log(result)
																				if(result.stdout.indexOf("ERROR")==-1)
																					msg.send "agent is deployed to docroot successfully"
																				else
																					msg.send "Error ocuured while deploying \n"+result2.stdout+'\n'+result2.stderr
																				ssh.execCommand('sudo rm -rf /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/Insights-master /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/agent.zip /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformAgents').then (result) ->
																					console.log("result ::: "+result)
																					console.log(result)
																					if(result.stdout=='')
																						console.log("removed folders")
																				
												else
													msg.send "Error ocuured while deploying \n"+result2.stderr
										else
											msg.send "Error occured while downloading \n"+result1.stderr
					else if(artifact=='agentfolder')
						nextdir='agents'
						ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/release/'+versiondir+'/'+nextdir).then (result) ->
							if(result.stdout=='')
								ssh.execCommand('sudo wget -O /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/agent.zip https://github.com/CognizantOneDevOps/Insights/archive/master.zip').then (result) ->
									console.log(result)
									if(result.stdout=='')
																	
										if(result.stderr.indexOf("ERROR")==-1)
											ssh.execCommand('sudo unzip -o /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/agent.zip'+' -d /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/').then (result2) ->
												console.log("unzip done::: ")
												console.log(result2)
												if(result2.stderr=='')
													
													ssh.execCommand('sudo rm -rf /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformAgents').then (result) ->
														console.log("result ::: "+result)
														console.log(result)
														if(result.stdout=='')
															ssh.execCommand('sudo mv /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/Insights-master/PlatformAgents /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformAgents').then (result) ->
																console.log("result ::: "+result)
																console.log(result)
																if(result.stdout=='')
																	console.log("moved folders")
																	ssh.execCommand('cd /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformAgents/; sudo rm -rf src test pom.xml .gitignore').then (result) ->
																		console.log("removed extra folder")
																		console.log(result)
																		if(result.stdout=='')
																			msg.send "agent folder deployed successfully"
																			ssh.execCommand('sudo rm -rf /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/Insights-master /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/agent.zip').then (result) ->
																				console.log("result ::: "+result)
																				console.log(result)
																				if(result.stdout=='')
																					console.log("removed folders")
																				
												else
													msg.send "Error ocuured while deploying \n"+result2.stderr
										else
											msg.send "Error occured while downloading \n"+result1.stderr											
					else if(artifact=='PlatformIndividualAgents')
						nextdir='agents'
						ssh.execCommand('sudo mkdir -p /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/').then (result) ->
							if(result.stdout=='')
								ssh.execCommand('sudo wget -O /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/agent.zip https://github.com/CognizantOneDevOps/Insights/archive/agent2.0.zip').then (result) ->
									
									if(result.stdout=='')
																	
										if(result.stderr.indexOf("ERROR")==-1)
											ssh.execCommand('sudo unzip -o /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/agent.zip'+' -d /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/').then (result2) ->
												console.log("unzip done::: ")
												
												if(result2.stderr=='')
													cmd1='cd /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/Insights-agent2.0/PlatformAgents/com/cognizant/devops/platformagents/agents/'
													cmd2='; ls -1 -d */'
													console.log(cmd1)
													
													ssh.execCommand(cmd1+'; ls -1 -d */').then (result) ->
														console.log(result)
														
														console.log("result::")
														#result.stdout+="\n"
														myarray=[]
														testcommand=''
														console.log(result)
														
														#resultdir=result.stdout.split("\n")
														#resultdir.splice(-1,1)
														#console.log(resultdir);
														if(result.stdout)
															result.stdout+="\n"
															resultdir=result.stdout.split("\n")
															resultdir.splice(-1,1)
															console.log(resultdir);
															for i in [0...resultdir.length]
																do (i) ->
																	ssh.execCommand(cmd1+resultdir[i]+cmd2).then (result) ->
																		result.stdout+="\n"
																		result1=result.stdout.split("\n")
																		result1.splice(-1,1)
																		result1.push(resultdir[i])
																		console.log(result1);
																		
																		for j in [0...result1.length-1]
																			do (j) ->
																				if(result1[result1.length-1].indexOf('DummyDataAgent')==-1 && result1[result1.length-1].indexOf('agentdaemon')==-1)
																					testcommand+='sudo mkdir -p /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/test/'+result1[j]+'; sudo chmod -R 777 /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/Insights-agent2.0'+'; sudo cp -r /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/Insights-agent2.0/PlatformAgents/com /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/test/'+result1[j]+'; cd /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/test/'+result1[j]+'com/cognizant/devops/platformagents/agents/; sudo rm -rf `ls -1 -d */`; sudo mkdir -p /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/test/'+result1[j]+'com/cognizant/devops/platformagents/agents/'+result1[result1.length-1]+result1[j]+'; '+cmd1.replace('cd','sudo cp -r')+result1[result1.length-1]+' '+'/var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/test/'+result1[j]+'com/cognizant/devops/platformagents/agents/'+'; cd '+'/var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/test/'+result1[j]+'com/cognizant/devops/platformagents/agents/'+result1[result1.length-1]+'; sudo rm -rf `ls -1 -d */`'+'; '+cmd1.replace('cd','sudo cp -r')+result1[result1.length-1]+result1[j]+' '+'/var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/test/'+result1[j]+'com/cognizant/devops/platformagents/agents/'+result1[result1.length-1]+'; cd /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/test/'+result1[j]+'com/cognizant/devops/platformagents/agents/'+result1[result1.length-1]+result1[j]+'; sudo ls -I "*.py" -I "*.json" | xargs -i sudo mv {} /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/test/'+result1[j]+'; sudo mkdir /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/'+result1[j]+'; cd /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/test/'+result1[j]+'; sudo zip -r /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/'+result1[j]+result1[j].slice(0, -1)+'.zip ./*;'
																					#myarray.push(testcommand)
																					
																					
															setTimeout ->
																# multi-line callbacks
																console.log(testcommand)
																ssh.execCommand(testcommand).then (result) ->
																	console.log(result)
																	ssh.execCommand('cd /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/; sudo rm -rf agent.zip Insights-agent2.0 test').then (result) ->
																		console.log('deleted temp files an folders')
																
															, 5000
															msg.send "PlatformIndividualAgents deployed successfully"								
				else if(envi=='docrootReleaseLatest')
					
					if(branch=='PlatformService')
						nextdir='serviceWar'
						
						ssh.execCommand('sudo cp -R /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformService-* '+ '/var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/PlatformService.war').then (result) ->
							
							if(result.stdout=='' && result.stderr=='')
								msg.send 'deployed '+branch+' in docrootReleaseLatest'
								ssh.execCommand('sudo touch /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md; sudo cat /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md | grep PlatformService.war=').then (result1) ->
									
									if(result1.stdout)
										ssh.execCommand('sudo sed -i -e "s/.*PlatformService.war.*/\PlatformService.war\=\ '+versiondir+'\ /g" /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md').then (result2) ->
											
									else
										ssh.execCommand('echo PlatformService.war= '+versiondir+' |  sudo tee -a /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md | grep -v ""').then (result3) ->
											
							else
								console.log(result)
								msg.send(result.stderr)
					else if(branch=='PlatformUI')
						nextdir='uiApp'
						ssh.execCommand('sudo cp -R /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/app.zip '+ '/var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/app.zip').then (result) ->
							if(result.stdout=='' && result.stderr=='')
								msg.send 'deployed '+branch+' in docrootReleaseLatest'
								ssh.execCommand('sudo touch /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md; cat /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md | grep app.zip=').then (result1) ->
									if(result1.stdout)
										ssh.execCommand('sudo sed -i -e "s/.*app.zip.*/\app.zip\=\ '+versiondir+'\ /g" /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md').then (result2) ->
											console.log(result2)
									else
										ssh.execCommand('echo app.zip= '+versiondir+' |  sudo tee -a /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md | grep -v ""').then (result3) ->
												console.log(result3)
							else
								console.log(result)
								msg.send(result.stderr)
					else if(branch=='PlatformInsights')
						nextdir='sparkJar'
						ssh.execCommand('sudo cp -R /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformInsights-* '+ '/var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/InSightsUI.zip').then (result) ->
							if(result.stdout=='' && result.stderr=='')
								msg.send 'deployed '+branch+' in docrootReleaseLatest'
								ssh.execCommand('sudo touch /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md; sudo cat /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md | grep InSightsUI.zip=').then (result1) ->
									if(result1.stdout)
										ssh.execCommand('sudo sed -i -e "s/.*InSightsUI.zip.*/\InSightsUI.zip\=\ '+versiondir+'\ /g" /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md').then (result2) ->
											console.log(result2)
									else
										ssh.execCommand('echo InSightsUI.zip= '+versiondir+' |  sudo tee -a /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md | grep -v ""').then (result3) ->
												console.log(result3)
							else
								console.log(result)
								msg.send(result.stderr)
					else if(branch=='PlatformEngine')
						nextdir='engineJar'
						ssh.execCommand('sudo cp -R /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformEngine-* '+ '/var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/PlatformEngine.jar').then (result) ->
							if(result.stdout=='' && result.stderr=='')
								msg.send 'deployed '+branch+' in docrootReleaseLatest'
								ssh.execCommand('sudo touch /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md; cat /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md | grep PlatformEngine.jar=').then (result1) ->
									if(result1.stdout)
										ssh.execCommand('sudo sed -i -e "s/.*PlatformEngine.jar.*/\PlatformEngine.jar\=\ '+versiondir+'\ /g" /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md').then (result2) ->
											console.log(result2)
									else
										ssh.execCommand('echo PlatformEngine.jar= '+versiondir+' |  sudo tee -a /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md | grep -v ""').then (result3) ->
												console.log(result3)
							else
								console.log(result)
								msg.send(result.stderr)
					else if(artifact=='agentzip')
						nextdir='agents'
						ssh.execCommand('sudo cp -R /var/www/html/insights_install/release/'+versiondir+'/'+nextdir+'/PlatformAgents.zip '+ '/var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/PlatformAgents.zip').then (result) ->
							if(result.stdout=='' && result.stderr=='')
								msg.send 'deployed '+branch+' in docrootReleaseLatest'
								ssh.execCommand('sudo touch /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md; cat /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md | grep PlatformAgents.zip=').then (result1) ->
									if(result1.stdout)
										ssh.execCommand('sudo sed -i -e "s/.*PlatformAgents.zip.*/\PlatformAgents.zip\=\ '+versiondir+'\ /g" /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md').then (result2) ->
											console.log(result2)
									else
										ssh.execCommand('echo PlatformAgents.zip= '+versiondir+' |  sudo tee -a /var/www/html/insights_install/installationScripts/latest/RHEL/artifacts/readme.md | grep -v ""').then (result3) ->
												console.log(result3)
										
							else
								console.log(result)
								msg.send(result.stderr)
			),(error) ->
					console.log('error in ssh :: '+error)
					msg.send 'Error connecting '+envi+"\n"+error
