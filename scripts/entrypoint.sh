#!/bin/bash
# Entrypoint script for Open Horizon Nginx Service
# Substitutes environment variables in HTML template and starts nginx

set -e

# Default message if not provided
MESSAGE="${MESSAGE:-Hello from Open Horizon!}"

# Substitute environment variables in the HTML template
echo "Substituting MESSAGE variable in HTML template..."
envsubst '${MESSAGE}' < /usr/share/nginx/html/index.html.template > /usr/share/nginx/html/index.html

echo "MESSAGE set to: ${MESSAGE}"
echo "Starting nginx..."

# Start nginx in foreground
exec nginx -g 'daemon off;'
