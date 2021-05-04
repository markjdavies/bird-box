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
      camera.CAPTURE_TIMEOUT = 60 # seconds
      camera.sensorMode = 3
      camera.resolution = (3280, 2464)
      camera.exposure_mode = 'sports'
      camera.iso = 0
      camera.awb_mode = 'off'
      camera.awb_gains = (1.16, 0.928)
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
