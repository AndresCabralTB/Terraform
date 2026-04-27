#!/bin/bash

# Start ngrok in the background
ngrok http 4040 --authtoken $NGROK_AUTHTOKEN &

/usr/local/bin/jenkins.sh
