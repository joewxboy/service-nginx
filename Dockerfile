# Multi-architecture Dockerfile for Open Horizon Nginx Service
# Supports: amd64 (x86_64) and arm64 (aarch64)

# Build argument for version (declared before FROM for base image selection if needed)
ARG SERVICE_VERSION=1.0.0

FROM nginx:latest

# Re-declare ARG after FROM to make it available in this build stage
ARG SERVICE_VERSION=1.0.0

# Metadata
LABEL maintainer="joe.pearson@us.ibm.com"
LABEL version="${SERVICE_VERSION}"
LABEL description="Open Horizon nginx service with customizable message"
LABEL org.opencontainers.image.source="https://github.com/joewxboy/service-nginx"

# Install envsubst for environment variable substitution
RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Copy nginx configuration
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Copy HTML template and assets
COPY nginx/html/index.html.template /usr/share/nginx/html/index.html.template
COPY nginx/html/openhorizon-icon-color.svg /usr/share/nginx/html/openhorizon-icon-color.svg

# Copy entrypoint script
COPY scripts/entrypoint.sh /scripts/entrypoint.sh
RUN chmod +x /scripts/entrypoint.sh

# Create health check file
RUN echo "OK" > /usr/share/nginx/html/health

# Expose HTTP port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Set default environment variable
ENV MESSAGE="Hello from Open Horizon!"

# Use entrypoint script to substitute variables
ENTRYPOINT ["/scripts/entrypoint.sh"]
