# bird-box

Bird box camera on Raspberry Pi with [Balena Cloud](https://www.balena.io/cloud) infrastructure

This is an implementation of the [Infrared Bird Box](https://projects.raspberrypi.org/en/projects/infrared-bird-box)
project. The guide there provides excellent detail on the hardware and YouTube setup.

Here I have implemented the streaming setup as a Docker image, targetted at a Balena device. I'm using a Raspberry Pi Zero WH.

Configuration is via ENV variables that can be set within the Balena UI. There are some settings relating to streaming parameters,
and some to camera exposure settings. The [YouTube streaming key described here](https://projects.raspberrypi.org/en/projects/infrared-bird-box/9)
is also set with an ENV variable.

I have given them defaults that work for me.

https://www.raspberrypi.org/documentation/raspbian/applications/camera.md

https://ffmpeg.org/ffmpeg.html#Main-options
