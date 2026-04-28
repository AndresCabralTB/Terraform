#!/bin/bash

echo "Setting up ngrok on http 4040" >> ngrok_output.log

# Start ngrok in the background
ngrok http 4040

echo "Ngrok started" >> ngrok_output.log

/usr/local/bin/jenkins.sh
