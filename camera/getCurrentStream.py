import json
from datetime import datetime

with open('/schedule/streams.json', 'r') as streamsFile:
    streamsData=streamsFile.read()
streamsJson = json.loads(streamsData)
streams = streamsJson['streams']

for stream in streams:
    startTime = datetime.strptime(stream['startTime'], "%Y-%m-%d %H:%M")
    endTime = datetime.strptime(stream['endTime'], "%Y-%m-%d %H:%M")
    timeNow = datetime.now()
    if startTime < timeNow and endTime > timeNow:
        timeRemaining = endTime - timeNow
        stream['secondsRemaining'] = str(int(round(timeRemaining.total_seconds())))
        streamJson = json.dumps(stream)
        print(streamJson)
