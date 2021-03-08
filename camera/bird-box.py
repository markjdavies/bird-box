#!/usr/bin/python

import os
import time
import picamera
from datetime import datetime


for attempt in range(100):
  filename = datetime.now().strftime('/pics/birdbox_%Y%m%d%H%M%S.jpg')
  try:
    with picamera.PiCamera() as camera:
      picamera.PiCamera.CAPTURE_TIMEOUT = 60 # seconds
      camera.resolution = (1280, 720)
      camera.awb_mode = 'off'
      camera.start_preview()
      # Camera warm-up time
      time.sleep(2)
      camera.capture(filename)
      camera.close()
  except Exception as e:
    os.remove(filename)
    print('Could not take still picture')
    print(e)
    time.sleep(5)
  else:
    print('Picture taken')
    break
else:
    print('Giving up on still picture')
