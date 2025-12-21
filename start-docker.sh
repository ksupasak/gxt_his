#!/bin/sh
# Start script for Docker - runs HTTP instead of HTTPS since nginx handles SSL
puma -b "tcp://0.0.0.0:3000"

