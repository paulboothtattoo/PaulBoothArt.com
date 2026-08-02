#!/bin/bash
cd "$(dirname "$0")"
echo "Starting PaulBoothArt.com preview at http://localhost:8080"
(sleep 1; open "http://localhost:8080") &
python3 -m http.server 8080
