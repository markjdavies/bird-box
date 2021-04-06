#!/usr/bin/python

import os
import time
import picamera
from datetime import datetime
from shutil import copyfile

while True:
  filename = '/pics/birdbox_latest.jpg'
  try:
    with picamera.PiCamera() as camera:
      picamera.PiCamera.CAPTURE_TIMEOUT = 20 # seconds
      camera.resolution = (1280, 720)
      camera.iso = 800
      camera.awb_mode = 'off'
      camera.awb_gains = (0.95, 0.95)
      camera.start_preview()
      # Camera warm-up time
      time.sleep(3)
      camera.capture(filename)
      camera.close()
  except Exception as e:
    print('Could not take still picture')
    print(e)
    time.sleep(5)
  else:
    print('Picture taken')
    dated_filename = datetime.now().strftime('/pics/birdbox_%Y%m%d%H%M%S.jpg')
    try:
      copyfile(filename, dated_filename)
    except IOError as e:
      print("Unable to copy file. %s" % e)
    except:
      print("Unexpected error")
    break
