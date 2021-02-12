#!/usr/bin/python

import json
import httplib2
import os
import sys

from datetime import datetime, timedelta
from apiclient.discovery import build
from apiclient.errors import HttpError
from oauth2client.client import flow_from_clientsecrets
from oauth2client.file import Storage
from oauth2client.tools import argparser, run_flow

# The CLIENT_SECRETS_FILE variable specifies the name of a file that contains
# the OAuth 2.0 information for this application, including its client_id and
# client_secret. You can acquire an OAuth 2.0 client ID and client secret from
# the {{ Google Cloud Console }} at
# {{ https://cloud.google.com/console }}.
# Please ensure that you have enabled the YouTube Data API for your project.
# For more information about using OAuth2 to access the YouTube Data API, see:
#   https://developers.google.com/youtube/v3/guides/authentication
# For more information about the client_secrets.json file format, see:
#   https://developers.google.com/api-client-library/python/guide/aaa_client_secrets
CLIENT_SECRETS_FILE = "/auth/client_secrets.json"

# This OAuth 2.0 access scope allows for full read/write access to the
# authenticated user's account.
YOUTUBE_READ_WRITE_SCOPE = "https://www.googleapis.com/auth/youtube"
YOUTUBE_API_SERVICE_NAME = "youtube"
YOUTUBE_API_VERSION = "v3"

# This variable defines a message to display if the CLIENT_SECRETS_FILE is
# missing.
MISSING_CLIENT_SECRETS_MESSAGE = """
WARNING: Please configure OAuth 2.0

To make this sample run you will need to populate the client_secrets.json file
found at:

   %s

with information from the {{ Cloud Console }}
{{ https://cloud.google.com/console }}

For more information about the client_secrets.json file format, please visit:
https://developers.google.com/api-client-library/python/guide/aaa_client_secrets
""" % os.path.abspath(os.path.join(os.path.dirname(__file__),
                                   CLIENT_SECRETS_FILE))

def get_authenticated_service(args):
  flow = flow_from_clientsecrets(CLIENT_SECRETS_FILE,
    scope=YOUTUBE_READ_WRITE_SCOPE,
    message=MISSING_CLIENT_SECRETS_MESSAGE)

  storage = Storage("/auth/%s-oauth2.json" % sys.argv[0])
  credentials = storage.get()

  if credentials is None or credentials.invalid:
    credentials = run_flow(flow, storage, args)

  return build(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION,
    http=credentials.authorize(httplib2.Http()))

# Create a liveBroadcast resource and set its title, scheduled start time,
# scheduled end time, and privacy status.
def insert_broadcast(youtube, options):
  startTime = datetime.strptime(options.start_time, "%Y-%m-%d %H:%M")
  endTime = startTime + timedelta(minutes = 359)
  insert_broadcast_response = youtube.liveBroadcasts().insert(
    part="snippet,status,contentDetails",
    body=dict(
      snippet=dict(
        title=options.broadcast_title,
        description=options.description,
        scheduledStartTime=options.start_time,
        scheduledEndTime=endTime.strftime('%Y-%m-%d %H:%M')
      ),
      status=dict(
        privacyStatus=options.privacy_status,
        selfDeclaredMadeForKids=False
      ),
      contentDetails=dict(
        enableAutoStart=True,
        enableAutoStop=True,
        latencyPreference="ultraLow"
      )
    )
  ).execute()

  # snippet = insert_broadcast_response["snippet"]

  return insert_broadcast_response["id"]

# Create a liveStream resource and set its title, format, and ingestion type.
# This resource describes the content that you are transmitting to YouTube.
def insert_stream(youtube, options):
  insert_stream_response = youtube.liveStreams().insert(
    part="snippet,cdn",
    body=dict(
      snippet=dict(
        title=options.stream_title
      ),
      cdn=dict(
        resolution="variable",
        format="variable",
        frameRate="variable",
        ingestionType="rtmp"
      )
    )
  ).execute()

  # snippet = insert_stream_response["snippet"]

  return insert_stream_response["id"]

# Update the video metadata
def update_video_metadata(youtube, video_id, options):
  # Update the video resource by calling the videos.update() method.
  youtube.videos().update(
    part='snippet',
    body=dict(
      snippet=dict(
        title=options.broadcast_title,
        description=options.description,
        categoryId=options.categoryId
      ),
      id=video_id
    )).execute()

# Bind the broadcast to the video stream. By doing so, you link the video that
# you will transmit to YouTube to the broadcast that the video is for.
def bind_broadcast(youtube, broadcast_id, stream_id, options):
  bind_broadcast_response = youtube.liveBroadcasts().bind(
    part="id,contentDetails",
    id=broadcast_id,
    streamId=stream_id
  ).execute()

  startTime = datetime.strptime(options.start_time, "%Y-%m-%d %H:%M")
  endTime = startTime + timedelta(minutes = 359)
  timeNow = datetime.now()
  timeRemaining = endTime - timeNow

  print ('{"broadcast":"%s","stream":"%s","startTime":"%s","endTime":"%s","timeRemaining":"%s"}' % (
    bind_broadcast_response["id"],
    bind_broadcast_response["contentDetails"]["boundStreamId"],
    options.start_time,
    endTime,
    int(round(timeRemaining.total_seconds()))))

if __name__ == "__main__":
  argparser.add_argument("--broadcast-title", help="Broadcast title",
    default="New Broadcast")
  argparser.add_argument("--privacy-status", help="Broadcast privacy status",
    default="private")
  argparser.add_argument("--start-time", help="Scheduled start time",
    default=datetime.now().strftime('%Y-%m-%d %H:%M'))
  argparser.add_argument("--end-time", help="Scheduled end time",
    default='2014-01-31T00:00:00.000Z')
  argparser.add_argument("--stream-title", help="Stream title",
    default="New Stream")
  argparser.add_argument("--description", help="Stream description", default="")
  argparser.add_argument("--categoryId", help="Category ID", default="15")
  args = argparser.parse_args()

  youtube = get_authenticated_service(args)
  try:
    broadcast_id = insert_broadcast(youtube, args)
    stream_id = insert_stream(youtube, args)
    update_video_metadata(youtube, broadcast_id, args)
    bind_broadcast(youtube, broadcast_id, stream_id, args)
  except HttpError as e:
    print(json.dumps(json.loads(e.content)))
