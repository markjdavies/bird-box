#!/usr/bin/python

import time
import picamera
from datetime import datetime


for i in range(100):
  for attempt in range(10):
    try:
      with picamera.PiCamera() as camera:
        picamera.PiCamera.CAPTURE_TIMEOUT = 60 # seconds
        camera.resolution = (1280, 720)
        # Camera warm-up time
        time.sleep(2)
        filename = datetime.now().strftime('/pics/birdbox_%Y%m%d%H%M%S.jpg')
        camera.capture(filename)
    except Exception as e:
      print('Could not take still picture')
      print(e)
      time.sleep(10)
    else:
      print('Picture taken')
      time.sleep(10)
      break
  else:
      print('Giving up on still picture')
    # we failed all the attempts - deal with the consequences.



