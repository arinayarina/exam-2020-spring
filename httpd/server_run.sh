#! /bin/bash
mkdir WWW
echo "Hello, World Server" > /WWW/index.html
nohup busybox httpd -f -h 'WWW' -p "${port}"
