from __future__ import unicode_literals
import boto3
from com.cognizant.devops.platformagents.core.BaseAgent import BaseAgent
from urllib import quote
import time
from dateutil import parser
import json, ast

class AwsCodePipeline(BaseAgent):
    def process(self):
        print "******"
        startFrom = self.config.get("StartFrom", '')
        startFrom = parser.parse(startFrom)
        startFrom = startFrom.strftime('%Y-%m-%dT%H:%M:%S')
        pipeline = self.config.get("pipeline", '')
        print pipeline
        since = self.tracking.get('lastupdated',None)
        if since == None:
            lastUpdated = startFrom
        else:
            since = parser.parse(since)
            since = since.strftime('%Y-%m-%dT%H:%M:%S')
            pattern = '%Y-%m-%dT%H:%M:%S'
            since = int(time.mktime(time.strptime(since,pattern)))
            lastUpdated = since
        client = boto3.client('codepipeline')
        tracking_data = []
        injectData = {}
        for names in pipeline:
            response = client.get_pipeline_state(
                 name=names
                 )
            print response
            date = str(response['created'])
            date = parser.parse(date)
            date = date.strftime('%Y-%m-%dT%H:%M:%S')
            pattern = '%Y-%m-%dT%H:%M:%S'
            date = int(time.mktime(time.strptime(date,pattern)))
            print date
            if since == None or date > since:
               injectData['pipelineName'] = str(response['pipelineName'])
               injectData['JobName'] = str(response['stageStates'][2]['stageName'])
               injectData['Status'] = str(response['stageStates'][1]['actionStates'][0]['latestExecution']['status'])
               injectData['Summary'] = str(response['stageStates'][1]['actionStates'][0]['latestExecution']['summary'])
               injectData['createTime'] = str(response['created'])
               start = str(response['stageStates'][1]['actionStates'][0]['latestExecution']['lastStatusChange'])
               start = parser.parse(start)
               start_e = start.strftime('%Y-%m-%dT%H:%M:%S')
               start_f = start.strftime('%Y-%m-%d')
               injectData['lastStatusChange'] = start_f
               pattern = '%Y-%m-%dT%H:%M:%S'
               epoch = int(time.mktime(time.strptime(start_e,pattern)))
               injectData['startTimeepoch'] = epoch
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
    AwsCodePipeline()
