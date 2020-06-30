#! /bin/bash
mkdir WWW
echo "Hello, World Server1" > /WWW/index.html
nohup busybox httpd -f -h 'WWW' -p "${port}"
