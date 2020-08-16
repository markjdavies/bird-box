modprobe v4l2_common && python bird-box.py &
cd /data
python -m SimpleHTTPServer 80
