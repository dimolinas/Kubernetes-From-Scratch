#!/bin/sh
curl --fail http://localhost:4567 || exit 1
echo "Health check passed"
exit 0