#! /bin/bash
set -e

hostIP=$(curl ifconfig.me/ip)
sleep 10

#ENV
yum install -y  wget unzip
cd /usr/ &&  mkdir INSIGHTS_HOME
cd /usr/INSIGHTS_HOME && wget $insightsConfigURL
cd /usr/INSIGHTS_HOME && unzip InSightsConfig.zip && rm -rf InSightsConfig.zip
cd /usr/INSIGHTS_HOME && cp -R InSightsConfig/.InSights/ .
cd /usr/INSIGHTS_HOME
export INSIGHTS_HOME=/usr/INSIGHTS_HOME
echo INSIGHTS_HOME=/usr/INSIGHTS_HOME | tee -a /etc/environment
echo "export INSIGHTS_HOME=/usr/INSIGHTS_HOME" | tee -a /etc/profile
source /etc/environment
source /etc/profile

#JAVA
yum update -y
cd /opt && wget $jdkURL
tar xzf jdk-8u151-linux-x64.tar.gz && rm -rf jdk-8u151-linux-x64.tar.gz

export JAVA_HOME=/opt/jdk1.8.0_151
 echo JAVA_HOME=/opt/jdk1.8.0_151  |  tee -a /etc/environment
 echo "export" JAVA_HOME=/opt/jdk1.8.0_151 |  tee -a /etc/profile
export JRE_HOME=/opt/jdk1.8.0_151/jre
 echo JRE_HOME=/opt/jdk1.8.0_151/jre |  tee -a /etc/environment
 echo "export" JRE_HOME=/opt/jdk1.8.0_151/jre |  tee -a /etc/profile
export PATH=$PATH:/opt/jdk1.8.0_151/bin:/opt/jdk1.8.0_151/jre/bin
 echo PATH=$PATH:/opt/jdk1.8.0_151/bin:/opt/jdk1.8.0_151/jre/bin |  tee -a /etc/environment
 alternatives --install /usr/bin/java java /opt/jdk1.8.0_151/bin/java 20000
 update-alternatives --install "/usr/bin/java" "java" "/opt/jdk1.8.0_151/bin/java" 1
 update-alternatives --install "/usr/bin/javac" "javac" "/opt/jdk1.8.0_151/bin/javac" 1
 update-alternatives --install "/usr/bin/javaws" "javaws" "/opt/jdk1.8.0_151/bin/javaws" 1
 update-alternatives --set java /opt/jdk1.8.0_151/bin/java
 update-alternatives --set javac /opt/jdk1.8.0_151/bin/javac
 update-alternatives --set javaws /opt/jdk1.8.0_151/bin/javaws
source /etc/environment
source /etc/profile


#UPDATE IPs -SERVER_CONFIG.JSON
elasticSearchEndpoint="http:\/\/$elasticIP:9200"
neo4jEndpoint="http:\/\/$neo4jIP:7474"
grafanaEndpoint="http:\/\/$hostIP:3000"
grafanaDBEndpoint="jdbc:postgresql:\/\/$postgresIP:5432\/grafana"
insightsDBUrl="jdbc:postgresql:\/\/$postgresIP:5432\/insight"
grafanaDBUrl="jdbc:postgresql:\/\/$postgresIP:5432\/grafana"
ldapUrl="ldap:\/\/$ldapIP:389"


configPath='/usr/INSIGHTS_HOME/.InSights/server-config.json'
sed -i -e "s/.*elasticSearchEndpoint.*/  \"elasticSearchEndpoint\": \"$elasticSearchEndpoint\"/g" $configPath
sed -i -e "s/.endpoint\":.*/\"endpoint\": \"$neo4jEndpoint\",/g" $configPath
sed -i -e "s/.*grafanaEndpoint.*/    \"grafanaEndpoint\": \"$grafanaEndpoint\",/g" $configPath
sed -i -e "s/.*grafanaDBEndpoint.*/    \"grafanaDBEndpoint\": \"$grafanaDBEndpoint\",/g" $configPath
sed -i -e "s/.*insightsDBUrl.*/\t\t\"insightsDBUrl\": \"$insightsDBUrl\",/g" $configPath
sed -i -e "s/.*grafanaDBUrl.*/\t\t\"grafanaDBUrl\": \"$grafanaDBUrl\"/g" $configPath
sed -i -e "s/.host\":.*/\"host\": \"$mqIP\",/g" $configPath
#LDAP update
sed -i -e "s/.*ldapUrl.*/\t\"ldapUrl\": \"$ldapUrl\",/g" $configPath
sed -i -e "s/.*bindDN.*/    \"bindDN\": \"$bindDN\",/g" $configPath
sed -i -e "s/.*bindPassword.*/    \"bindPassword\": \"$bindPassword\",/g" $configPath
sed -i -e "s/.*searchBaseDN.*/    \"searchBaseDN\": \"$searchBaseDN\",/g" $configPath



sed -i 's/\r$//g' $configPath


#GRAFANA
cd -
mkdir grafana-v4.6.2 && cd grafana-v4.6.2
wget $grafanaURL
tar -zxvf grafana-4.6.2.linux-x64.tar.gz
wget $grafanaLDAP
cp ldap.toml ./grafana-4.6.2/conf/ldap.toml
wget $grafanaDefaults
cp defaults.ini ./grafana-4.6.2/conf/defaults.ini
export GRAFANA_HOME=/opt/grafana-v4.6.2/
sed -i -e "s/host = localhost:5432/host = $postgresIP:5432/g"  ./grafana-4.6.2/conf/defaults.ini
cd grafana-4.6.2 && nohup ./bin/grafana-server &
sleep 40
echo $hostIP
echo $! > grafana-pid.txt
curl -X POST -u admin:admin -H "Content-Type: application/json" -d '{"name":"PowerUser","email":"PowerUser@PowerUser.com","login":"PowerUser","password":"C0gnizant@1"}' http://$hostIP:3000/api/admin/users
sleep 10
echo "GRAFANA URL :"$hostIP:3000


#TOMCAT
cd /opt && wget $insightsUI
unzip InSightsUI.zip && rm -rf InSightsUI.zip
sleep 20
wget $insightsWar
wget $tomcatURL
tar -zxvf apache-tomcat-8.5.27.tar.gz && rm -rf apache-tomcat-8.5.27.tar.gz
cp -R InSightsUI/app /opt/apache-tomcat-8.5.27/webapps/
cp PlatformService.war /opt/apache-tomcat-8.5.27/webapps/
cd apache-tomcat-8.5.27 && chmod -R 755 /opt/apache-tomcat-8.5.27
rm -rf /opt/PlatformService.war
exec /opt/apache-tomcat-8.5.27/bin/catalina.sh run