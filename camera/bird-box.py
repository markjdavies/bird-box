#!/usr/bin/python

import os
import time
import picamera
from datetime import datetime
from shutil import copyfile
from ast import literal_eval as make_tuple

while True:
  filename = '/pics/birdbox_latest.jpg'
  try:
    with picamera.PiCamera() as camera:
      # Timeout must be referenced on class not the instance, due to this bug: https://github.com/waveform80/picamera/issues/329
      picamera.PiCamera.CAPTURE_TIMEOUT = int(os.environ.get('STILL_CAPTURE_TIMEOUT', '60')) # seconds
      # set sensor_mode twice, to be sure: https://picamera.readthedocs.io/en/release-1.13/api_camera.html#picamera.PiCamera.sensor_mode
      camera.sensor_mode = int(os.environ.get('STILL_SENSOR_MODE', '3'))
      camera.sensor_mode = int(os.environ.get('STILL_SENSOR_MODE', '3'))
      camera.resolution = make_tuple(os.environ.get('STILL_RESOLUTION', '(3280, 2464)'))
      camera.exposure_mode = 'sports'
      camera.iso = 0
      camera.awb_mode = 'off'
      camera.awb_gains = make_tuple(os.environ.get('STILL_AWB_GAINS', '(1.16, 0.928)'))
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
