from __future__ import unicode_literals
import boto3
from com.cognizant.devops.platformagents.core.BaseAgent import BaseAgent
from urllib import quote
import time
from dateutil import parser
import json, ast
from requests.auth import HTTPBasicAuth
import requests

class BuildMaster(BaseAgent):
    def process(self):
        startFrom = self.config.get("StartFrom", '')
        token = self.config.get("token", '')
        baseurl = self.config.get("endpoint", '')
        userid = self.config.get("userid", '')
        passwd = self.config.get("passwd", '')
        app = self.config.get("appID", '')
        startFrom = parser.parse(startFrom)
        startFrom = startFrom.strftime('%Y-%m-%dT%H:%M:%S')
        for id in app:
            release = []
            url = baseurl+"Builds_GetBuilds?API_Key="+token+"&Application_Id="+id+"&ReleaseStatus_Name=Active"
            response = self.getResponse(url, 'GET', userid, passwd, None)
            for rel in response:
                rel_name=rel['Release_Number']
                if rel_name not in release:
                    release.append(rel_name)
            for name in release:
                url = baseurl+"Builds_GetBuilds?API_Key="+token+"&Application_Id="+id+"&ReleaseStatus_Name=Active"+"&Release_Number="+name
                response = self.getResponse(url, 'GET', userid, passwd, None)
                injectData = {}
                tracking_data = []
                track=id+"-"+name
                for hierarchy in response:
                    injectData = {}
                    since = self.tracking.get(track,None)
                    if since == None:
                        lastUpdated = startFrom
                    else:
                        since = parser.parse(since)
                        since = since.strftime('%Y-%m-%dT%H:%M:%S')
                        lastUpdated = since
                    if 'Current_ExecutionStart_Date' in hierarchy:
                        date = hierarchy['Current_ExecutionStart_Date']
                        date = parser.parse(date)
                        date = date.strftime('%Y-%m-%dT%H:%M:%S')
                        if since == None or date > since:
                            injectData['appId'] = hierarchy['Application_Id']
                            injectData['applicationName'] = hierarchy['Application_Name']
                            injectData['buildId'] = hierarchy['Build_Number']
                            injectData['buildstatusName'] = hierarchy['BuildStatus_Name']
                            injectData['releaseNumber'] = hierarchy['Release_Number']
                            injectData['releasestatusName'] = hierarchy['ReleaseStatus_Name']
                            injectData['releaseName'] = hierarchy['Release_Name']
                            if 'Current_Environment_Name' in hierarchy:
                                injectData['currentEnv'] = hierarchy['Current_Environment_Name']
                            if 'Current_ExecutionStatus_Name' in hierarchy:
                                injectData['status'] = hierarchy['Current_ExecutionStatus_Name']
                            start = hierarchy['Current_ExecutionStart_Date']
                            start = parser.parse(start)
                            start = start.strftime('%Y-%m-%dT%H:%M:%S')
                            injectData['createTime'] = start
                            tracking_data.append(injectData)
                            fromDateTime = response[0]['Current_ExecutionStart_Date']
                            fromDateTime = parser.parse(fromDateTime)
                            fromDateTime = fromDateTime.strftime('%Y-%m-%dT%H:%M:%S')
                        else:
                            fromDateTime = response[0]['Current_ExecutionStart_Date']
                            fromDateTime = parser.parse(fromDateTime)
                            fromDateTime = fromDateTime.strftime('%Y-%m-%dT%H:%M:%S')
                if tracking_data!=[]:
                    self.tracking[track] = fromDateTime
                    self.publishToolsData(tracking_data)
                    self.updateTrackingJson(self.tracking)
if __name__ == "__main__":
    BuildMaster()
