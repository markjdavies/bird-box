#!/usr/bin/python

import os
import time
import picamera
from datetime import datetime

while True:
  filename = datetime.now().strftime('/pics/birdbox_%Y%m%d%H%M%S.jpg')
  try:
    with picamera.PiCamera() as camera:
      picamera.PiCamera.CAPTURE_TIMEOUT = 20 # seconds
      camera.resolution = (1280, 720)
      camera.iso = 800
      camera.awb_mode = 'off'
      camera.awb_gains = (1, 1)
      # camera.awb_mode = 'off'
      camera.start_preview()
      # Camera warm-up time
      time.sleep(3)
      camera.capture(filename)
      camera.close()
  except Exception as e:
    try:
      print('Could not take still picture')
      print(e)
      os.remove(filename)
    except Exception as e2:
      print('Could not remove file')
      print(e)
    time.sleep(5)
  else:
    print('Picture taken')
    break
