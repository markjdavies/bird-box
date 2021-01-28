#!/usr/bin/python

import time
import picamera
from datetime import datetime

with picamera.PiCamera() as camera:
    camera.resolution = (1280, 720)
    # Camera warm-up time
    time.sleep(2)
    filename = datetime.now().strftime('/pics/birdbox_%Y%m%d%H%M%S.jpg')
    camera.capture(filename)

print('Picture taken')
time.sleep(10)
