# Open Horizon Nginx Service

A multi-architecture Open Horizon edge service that serves a simple web page using nginx. Supports both arm64 and amd64 architectures with a customizable message via userInput variable.

## Overview

This service demonstrates how to create a basic Open Horizon edge service using the official nginx container. It serves a simple web page that displays a customizable message, making it ideal for:

- Learning Open Horizon service development
- Testing edge node deployments
- Demonstrating multi-architecture support
- Serving as a template for web-based edge services

## Features

- **Multi-Architecture Support**: Runs on both amd64 (x86_64) and arm64 (aarch64) devices
- **Customizable Message**: Configure the displayed message via Open Horizon userInput
- **Lightweight**: Based on official nginx container
- **Simple Deployment**: Easy to build, publish, and deploy
- **Health Monitoring**: Built-in health check endpoint

## Prerequisites

### Required Tools

- **Container Engine**: Docker (version 20.10+) or Podman (version 3.0+)
  - Docker: Requires buildx support for multi-architecture builds
  - Podman: Native multi-architecture support
- **Open Horizon CLI**: `hzn` command-line tool installed
- **Open Horizon Account**: Access to an Open Horizon Management Hub
- **Container Registry Access**: DockerHub, Quay.io, or private registry

### Environment Variables

Set these environment variables before building and publishing:

```bash
export HZN_ORG_ID=<your-org-id>
export HZN_EXCHANGE_USER_AUTH=<your-username>:<your-token>
export DOCKER_REGISTRY=<your-registry>  # e.g., docker.io/yourusername
```

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/joewxboy/service-nginx.git
cd service-nginx
```

### 2. Build the Service

The Makefile automatically detects whether you have Docker or Podman installed:

```bash
# Build for your current architecture (auto-detects docker/podman)
make build

# Or build for specific architecture
make build-amd64
make build-arm64

# Force a specific container engine
CONTAINER_ENGINE=podman make build
CONTAINER_ENGINE=docker make build
```

### 3. Test Locally

```bash
# Run the container locally
make test

# Access the web page
curl http://localhost:8080

# Or open in browser
open http://localhost:8080
```

### 4. Publish to Open Horizon

```bash
# Build and push Docker images
make push

# Publish service definition
make publish-service

# Publish deployment pattern
make publish-pattern
```

### 5. Deploy to Edge Node

```bash
# Register node with pattern
hzn register -p pattern-service-nginx -s service-nginx --serviceorg $HZN_ORG_ID \
  -i message="Hello from my edge node!"

# Verify deployment
hzn service list
hzn agreement list

# Check the web page
curl http://localhost:8080
```

## Building the Service

### Local Build

Build for your current architecture:

```bash
make build
```

### Multi-Architecture Build

Build for both amd64 and arm64:

```bash
# With Docker (uses buildx - first time setup)
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
make build-all-arches

# With Podman (no setup needed)
CONTAINER_ENGINE=podman make build-all-arches

# Auto-detect (uses whichever is available)
make build-all-arches
```

**Note**: Docker uses buildx for efficient multi-arch builds, while Podman builds each architecture separately.

### Build Variables

Customize the build with these variables:

```bash
make build \
  CONTAINER_ENGINE=podman \
  DOCKER_REGISTRY=docker.io/myuser \
  SERVICE_VERSION=1.0.1
```

Available variables:
- `CONTAINER_ENGINE`: Container engine to use (auto-detected, or set to `docker` or `podman`)
- `DOCKER_REGISTRY`: Container registry URL
- `SERVICE_VERSION`: Version tag for the service

## Publishing to Open Horizon

### 1. Publish Service Definition

```bash
make publish-service
```

This publishes the service definition to the Open Horizon Exchange for both architectures.

### 2. Publish Deployment Pattern

```bash
make publish-pattern
```

Creates a deployment pattern that can be used for node registration.

### 3. Publish Deployment Policy

```bash
make publish-policy
```

Creates a deployment policy for autonomous deployment.

### Verify Publication

```bash
# List published services
hzn exchange service list $HZN_ORG_ID/service-nginx

# View service details
hzn exchange service list $HZN_ORG_ID/service-nginx_1.0.0_amd64 -l

# List patterns
hzn exchange pattern list $HZN_ORG_ID/pattern-service-nginx
```

## Deploying the Service

### Pattern-Based Deployment

Register your edge node with the service pattern:

```bash
hzn register -p pattern-service-nginx \
  -s service-nginx \
  --serviceorg $HZN_ORG_ID \
  -i message="Welcome to Open Horizon!"
```

### Policy-Based Deployment

1. Create a node policy:

```bash
cat << EOF | hzn policy new
{
  "properties": [
    {
      "name": "purpose",
      "value": "web-server"
    }
  ],
  "constraints": []
}
EOF
```

2. Register the node:

```bash
hzn register -p ""
```

3. The service will deploy automatically based on matching policies.

### Verify Deployment

```bash
# Check service status
hzn service list

# View agreements
hzn agreement list

# Check container logs
docker logs $(docker ps -q --filter ancestor=service-nginx)

# Test the web page
curl http://localhost:8080
```

## Configuration

### UserInput Variables

The service accepts the following userInput variable:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `message` | string | "Hello from Open Horizon!" | The message displayed on the web page |

### Setting UserInput Values

**During Registration:**

```bash
hzn register -p pattern-service-nginx \
  -i message="Custom message here"
```

**Using userinput.json:**

```json
{
  "services": [
    {
      "org": "$HZN_ORG_ID",
      "url": "service-nginx",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": {
        "message": "My custom message"
      }
    }
  ]
}
```

```bash
hzn register -p pattern-service-nginx -f horizon/userinput.json
```

### Environment Variables

The service uses these environment variables internally:

| Variable | Description |
|----------|-------------|
| `MESSAGE` | The message to display (set from userInput) |

## Testing

### Local Container Testing

```bash
# Using the Makefile (auto-detects docker/podman)
make test

# Or manually with Docker
docker run -d -p 8080:80 --name nginx-test service-nginx:1.0.0

# Or manually with Podman
podman run -d -p 8080:80 --name nginx-test service-nginx:1.0.0

# Run with custom message
docker run -d -p 8080:80 -e MESSAGE="Test message" --name nginx-test service-nginx:1.0.0

# Test the endpoint
curl http://localhost:8080

# View logs
docker logs nginx-test  # or: podman logs nginx-test

# Clean up
make stop-test  # or: docker stop nginx-test && docker rm nginx-test
```

### Edge Node Testing

```bash
# Check service status
hzn service list

# View service logs
hzn service log -f service-nginx

# Test the web page
curl http://localhost:8080

# Check health endpoint
curl http://localhost:8080/health
```

### Multi-Architecture Testing

Test on different architectures:

```bash
# On amd64 device
make test

# On arm64 device (Raspberry Pi, Jetson, etc.)
make test
```

## Troubleshooting

### Service Not Starting

```bash
# Check service status
hzn service list

# View detailed logs
hzn eventlog list

# Check Docker logs
docker logs $(docker ps -a -q --filter ancestor=service-nginx)
```

### Port Already in Use

If port 8080 is already in use, modify the service definition or use a different port:

```bash
# Check what's using the port
lsof -i :8080

# Stop conflicting service
docker stop <container-id>
```

### Image Pull Failures

```bash
# Verify image exists (with Docker)
docker pull $DOCKER_REGISTRY/service-nginx_amd64:1.0.0

# Or with Podman
podman pull $DOCKER_REGISTRY/service-nginx_amd64:1.0.0

# Check registry authentication
docker login $DOCKER_REGISTRY  # or: podman login $DOCKER_REGISTRY
```

### Agreement Not Forming

```bash
# Check node status
hzn node list

# View agreement attempts
hzn eventlog list -f

# Verify service is published
hzn exchange service list $HZN_ORG_ID/service-nginx
```

## Architecture

### Service Components

```
┌─────────────────────────────────────┐
│     Open Horizon Management Hub     │
│  (Exchange, AgBot, CSS, Vault)      │
└─────────────────┬───────────────────┘
                  │
                  │ Service Definition
                  │ Pattern/Policy
                  │
┌─────────────────▼───────────────────┐
│         Edge Node (Agent)           │
│  ┌───────────────────────────────┐  │
│  │   Docker Container            │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │   Nginx Web Server      │  │  │
│  │  │   - Serves HTML page    │  │  │
│  │  │   - Displays message    │  │  │
│  │  │   - Port 8080           │  │  │
│  │  └─────────────────────────┘  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### File Structure

```
service-nginx/
├── Dockerfile              # Multi-arch container definition
├── service.json            # Open Horizon service definition
├── Makefile                # Build and publish automation
├── horizon/
│   ├── pattern.json       # Deployment pattern
│   ├── policy.json        # Deployment policy
│   └── userinput.json     # Example user input
├── nginx/
│   ├── nginx.conf         # Nginx configuration
│   └── html/
│       └── index.html     # Web page template
├── scripts/
│   ├── entrypoint.sh      # Container startup script
│   └── test-service.sh    # Testing script
└── docs/
    ├── README.md          # This file
    ├── AGENTS.md          # AI agent documentation
    ├── MAINTAINERS.md     # Maintainer information
    └── CONTRIBUTORS.md    # Contribution guidelines
```

## Development

### Making Changes

1. Modify the service code
2. Update version in Makefile and service.json
3. Build and test locally
4. Publish updated service
5. Update documentation

### Adding Features

- Modify `nginx/html/index.html` for UI changes
- Update `nginx/nginx.conf` for server configuration
- Add new userInput variables in `service.json`
- Update `scripts/entrypoint.sh` for new environment variables

## Contributing

We welcome contributions! Please see [CONTRIBUTORS.md](CONTRIBUTORS.md) for guidelines.

### How to Contribute

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Security

### Reporting Security Issues

Please report security vulnerabilities to: joe.pearson@us.ibm.com

### Security Best Practices

- Keep base images updated
- Use signed service definitions in production
- Implement proper access controls
- Monitor service logs regularly

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/joewxboy/service-nginx/issues)
- **Documentation**: [Open Horizon Docs](https://open-horizon.github.io/)
- **Community**: [Open Horizon Slack](https://lfedge.slack.com/)

## Maintainers

- Joe Pearson (@joewxboy) - joe.pearson@us.ibm.com

See [MAINTAINERS.md](MAINTAINERS.md) for more information.

## Acknowledgments

- Open Horizon community
- Nginx project
- LF Edge community

## Related Projects

- [Open Horizon Examples](https://github.com/open-horizon/examples)
- [Open Horizon Documentation](https://github.com/open-horizon/open-horizon.github.io)
- [Nginx Official](https://github.com/nginx/nginx)

## Version History

- **1.0.0** (2026-02-04): Initial release
  - Multi-arch support (amd64, arm64)
  - Customizable message via userInput
  - Basic nginx web server
  - Complete documentation
