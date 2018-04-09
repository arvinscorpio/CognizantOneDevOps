from __future__ import unicode_literals
import boto3
from com.cognizant.devops.platformagents.core.BaseAgent import BaseAgent
from urllib import quote
import time
from dateutil import parser
import json, ast

class AwsCodeDeploy(BaseAgent):
    def process(self):
        startFrom = self.config.get("StartFrom", '')
        startFrom = parser.parse(startFrom)
        startFrom = startFrom.strftime('%Y-%m-%dT%H:%M:%S')
        since = self.tracking.get('lastupdated',None)
        if since == None:
            lastUpdated = startFrom
        else:
            since = parser.parse(since)
            since = since.strftime('%Y-%m-%dT%H:%M:%S')
            pattern = '%Y-%m-%dT%H:%M:%S'
            since = int(time.mktime(time.strptime(since,pattern)))
            lastUpdated = since
        client = boto3.client('codedeploy')
        deployment = {
           'Spot' : ['Dev','QA'],
           'SWIFT' : ['QA'],
           'test' : ['Dev']
        }
        deploystr = ast.literal_eval(json.dumps(deployment))
        getlist = []
        deployIDlist = []
        tracking_data = []
        for app in deploystr.keys():
            for groups in deploystr[app]:
                response = client.list_deployments(
                applicationName=app,
                deploymentGroupName=groups
                )
                #print response
                getlist = [[str(deployments) for deployments in response['deployments']] for deployments in response]
                getlist = [item for items in getlist for item in items]
                deployId=list(set(getlist))
                for n in deployId:
                    injectData = {}
                    string = {}
                    client = boto3.client('codedeploy')
                    deploy = client.get_deployment(
                    deploymentId=n
                    )
                    date = str(deploy['deploymentInfo']['createTime'])
                    date = parser.parse(date)
                    date = date.strftime('%Y-%m-%dT%H:%M:%S')
                    pattern = '%Y-%m-%dT%H:%M:%S'
                    date = int(time.mktime(time.strptime(date,pattern)))
                    if since == None or date > since:
                        injectData['status'] = str(deploy['deploymentInfo']['status'])
                        injectData['applicationName'] = str(deploy['deploymentInfo']['applicationName'])
                        injectData['deploymentId'] = str(deploy['deploymentInfo']['deploymentId'])
                        injectData['deployType'] = str(deploy['deploymentInfo']['deploymentStyle']['deploymentType'])
                        injectData['deploymentGroupName'] = str(deploy['deploymentInfo']['deploymentGroupName'])
                        injectData['createTime'] = str(deploy['deploymentInfo']['createTime'])
                        start = str(deploy['deploymentInfo']['createTime'])
                        start = parser.parse(start)
                        start_e = start.strftime('%Y-%m-%dT%H:%M:%S')
                        start_f = start.strftime('%Y-%m-%d')
                        injectData['startTime'] = start_f
                        pattern = '%Y-%m-%dT%H:%M:%S'
                        epoch = int(time.mktime(time.strptime(start_e,pattern)))
                        injectData['startTimeepoch'] = epoch
                        complete = str(deploy['deploymentInfo']['completeTime'])
                        complete = parser.parse(complete)
                        complete = complete.strftime('%Y-%m-%dT%H:%M:%S')
                        epoch = int(time.mktime(time.strptime(complete,pattern)))
                        injectData['completionTime'] = epoch
                        injectData['lastUpdated'] = lastUpdated
                        string = ast.literal_eval(json.dumps(injectData))
                        tracking_data.append(string)
                        seq = [x['createTime'] for x in tracking_data]
                        fromDateTime = max(seq)
                        fromDateTime = parser.parse(fromDateTime)
                        fromDateTime = fromDateTime.strftime('%Y-%m-%dT%H:%M:%S')
                    else:
                        fromDateTime = lastUpdated
        self.tracking["lastupdated"] = fromDateTime
        if tracking_data!=[]:
            self.publishToolsData(tracking_data)
            self.updateTrackingJson(self.tracking)
if __name__ == "__main__":
    AwsCodeDeploy()
