#! /bin/bash
set -e

yum install wget tar unzip -y

#Assign to variables
neo4jEndpoint="http:\/\/$neo4jIP:7474"
insightsDBUrl="jdbc:postgresql:\/\/$postgresIP:5432\/insight"
grafanaDBUrl="jdbc:postgresql:\/\/$postgresIP:5432\/grafana"


#set Env
cd /usr/ && mkdir INSIGHTS_HOME
cd INSIGHTS_HOME
wget $insightsConfig
unzip InSightsConfig.zip && rm -rf InSightsConfig.zip
cp -R InSightsConfig/.InSights/ .
export INSIGHTS_HOME=/usr/INSIGHTS_HOME
mkdir /opt/insightsengine
cd /opt/insightsengine
export INSIGHTS_ENGINE=/opt/insightsengine
wget $jarURL



cd /opt/ && wget $jdkURL
tar xzf jdk-8u151-linux-x64.tar.gz
export JAVA_HOME=/opt/jdk1.8.0_151
echo JAVA_HOME=/opt/jdk1.8.0_151  | tee -a /etc/environment
echo "export" JAVA_HOME=/opt/jdk1.8.0_151 | tee -a /etc/profile
export JRE_HOME=/opt/jdk1.8.0_151/jre
echo JRE_HOME=/opt/jdk1.8.0_151/jre | tee -a /etc/environment
echo "export" JRE_HOME=/opt/jdk1.8.0_151/jre | tee -a /etc/profile
export PATH=$PATH:/opt/jdk1.8.0_151/bin:/opt/jdk1.8.0_151/jre/bin
echo PATH=$PATH:/opt/jdk1.8.0_151/bin:/opt/jdk1.8.0_151/jre/bin | tee -a /etc/environment


#update config
configPath='/usr/INSIGHTS_HOME/.InSights/server-config.json'
sed -i -e "s/.endpoint\":.*/\"endpoint\": \"$neo4jEndpoint\",/g" $configPath
sed -i -e "s/.host\":.*/\"host\": \"$mqIP\",/g" $configPath
sed -i -e "s/.*insightsDBUrl.*/\t\t\"insightsDBUrl\": \"$insightsDBUrl\",/g" $configPath
sed -i -e "s/.*grafanaDBUrl.*/\t\t\"grafanaDBUrl\": \"$grafanaDBUrl\"/g" $configPath
sed -i 's/\r$//g' $configPath

source /etc/environment
source /etc/profile

#JAR EXEC

exec java  -Xmx1024M -Xms500M  -jar /opt/insightsengine/PlatformEngine.jar >/opt/logPlatformEngine.txt
