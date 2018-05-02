Steps to execute Insights Bot
*****************************
1.Clone this repository.

2.Export the environmental variables mentioned below

	export NEXUS_URL=                         ##Repository URL to download artifacts and deploy to target server

	export NEXUS_USERNAME=

	export NEXUS_PASSWORD=

	export QA_ENV=

	export DOC_ROOT_ENV=

	export QA_SPARK_ENV=

	export PROD_ENV=

	export PROD_SPARK_ENV=

	export HUBOT_SLACK_TOKEN=                 ##Get Slack Token of the App from respective Slack 

	
3.Start the Bot executing the below command, 

	./bin/hubot - a slack

Note: Bot ssh to target server and deploy artifacts. Respective target environment server's '.pem' files has to be placed in the parent directory as mentioned in the scripts/bot.coffee script.
