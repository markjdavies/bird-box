#!/usr/bin/python

import time
import picamera

with picamera.PiCamera() as camera:
    camera.resolution = (1280, 720)
    # Camera warm-up time
    time.sleep(2)
    camera.capture('/data/image.jpg')

print('Picture taken')
time.sleep(10)
