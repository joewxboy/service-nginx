# AI Agents Integration Guide

This document describes how AI agents can interact with, deploy, and manage the Open Horizon Nginx service.

## Overview

AI agents can assist with various aspects of this Open Horizon service, from deployment and configuration to monitoring and troubleshooting. This guide provides patterns, examples, and best practices for agent integration.

## Supported Agent Types

### 1. Large Language Model (LLM) Agents

**Examples**: ChatGPT, Claude, Gemini, GitHub Copilot Chat

**Capabilities**:
- Generate deployment commands
- Troubleshoot service issues
- Explain configuration options
- Create custom service variations
- Generate documentation

**Integration Methods**:
- Natural language queries
- Code generation
- Configuration assistance
- Documentation generation

### 2. Automation Agents

**Examples**: GitHub Actions, Jenkins, Ansible, Terraform

**Capabilities**:
- Automated builds and deployments
- CI/CD pipeline integration
- Infrastructure as Code (IaC)
- Automated testing

**Integration Methods**:
- API calls to Open Horizon Exchange
- Docker registry operations
- Git repository automation

### 3. Monitoring and Management Agents

**Examples**: Prometheus, Grafana, Nagios, Custom monitoring tools

**Capabilities**:
- Service health monitoring
- Performance metrics collection
- Alerting and notifications
- Automated remediation

**Integration Methods**:
- Open Horizon REST APIs
- Docker container monitoring
- Log aggregation
- Metrics collection

## Agent Interaction Patterns

### Pattern 1: Service Deployment Assistant

**Use Case**: Help users deploy the service to their edge nodes

**Agent Capabilities**:
- Validate prerequisites
- Generate deployment commands
- Customize userInput variables
- Verify successful deployment

**Example Interaction**:

```
User: "Deploy the nginx service to my edge node with a custom message"

Agent: "I'll help you deploy the service. First, let me verify your setup:

1. Check if you have the required environment variables:
   - HZN_ORG_ID
   - HZN_EXCHANGE_USER_AUTH

2. Here's the deployment command with your custom message:

   hzn register -p pattern-service-nginx \
     -s service-nginx \
     --serviceorg $HZN_ORG_ID \
     -i message="Your custom message here"

3. After registration, verify with:
   hzn agreement list
   curl http://localhost:8080

Would you like me to explain any of these steps?"
```

### Pattern 2: Configuration Generator

**Use Case**: Generate custom configurations for specific use cases

**Agent Capabilities**:
- Create custom userInput configurations
- Generate deployment policies
- Customize service definitions
- Create node policies

**Example Interaction**:

```
User: "Create a deployment policy that only deploys to ARM devices"

Agent: "Here's a deployment policy for ARM devices only:

{
  "label": "nginx-arm-only",
  "description": "Deploy nginx service only to ARM devices",
  "service": {
    "name": "service-nginx",
    "org": "$HZN_ORG_ID",
    "arch": "arm64",
    "serviceVersions": [
      {
        "version": "1.0.0"
      }
    ]
  },
  "properties": [],
  "constraints": [
    "openhorizon.arch == arm64"
  ]
}

Save this to a file and publish with:
hzn exchange deployment addpolicy -f service.policy.json nginx-arm-policy
"
```

### Pattern 3: Troubleshooting Assistant

**Use Case**: Diagnose and resolve service issues

**Agent Capabilities**:
- Analyze error messages
- Suggest solutions
- Generate diagnostic commands
- Provide step-by-step fixes

**Example Interaction**:

```
User: "My nginx service isn't starting"

Agent: "Let's troubleshoot this step by step:

1. Check if the service is registered:
   hzn service list

2. View recent events:
   hzn eventlog list -f

3. Check Docker container status:
   docker ps -a | grep nginx

4. View container logs:
   docker logs $(docker ps -a -q --filter ancestor=service-nginx)

5. Common issues and solutions:
   - Port 8080 already in use: Check with 'lsof -i :8080'
   - Image pull failure: Verify registry access
   - Agreement not forming: Check node policy constraints

Please run these commands and share the output for further assistance."
```

### Pattern 4: Multi-Architecture Build Assistant

**Use Case**: Help build and publish multi-architecture images

**Agent Capabilities**:
- Set up Docker buildx
- Generate build commands
- Verify multi-arch manifests
- Troubleshoot build issues

**Example Interaction**:

```
User: "How do I build this for both ARM and x86?"

Agent: "Here's how to build for multiple architectures:

1. Set up Docker buildx (one-time setup):
   docker buildx create --name multiarch --use
   docker buildx inspect --bootstrap

2. Build for both architectures:
   
   # With Docker (uses buildx)
   docker buildx build --platform linux/amd64,linux/arm64 \
     -t $DOCKER_REGISTRY/service-nginx:1.0.0 \
     --push .
   
   # With Podman (builds separately)
   podman build --platform linux/amd64 -t $DOCKER_REGISTRY/service-nginx:1.0.0 .
   podman build --platform linux/arm64 -t $DOCKER_REGISTRY/service-nginx:1.0.0 .

3. Verify the multi-arch manifest:
   docker manifest inspect $DOCKER_REGISTRY/service-nginx:1.0.0

4. Or use the Makefile (auto-detects docker/podman):
   make build-all-arches
   make push
   
   # Or force a specific container engine:
   CONTAINER_ENGINE=podman make build-all-arches

The images will be available for both architectures automatically."
```

## API Endpoints for Agents

### Container Engine Compatibility

The service supports both Docker and Podman as container engines:

**Docker**:
- Uses buildx for efficient multi-architecture builds
- Requires buildx setup for multi-arch support
- Standard Docker commands work as expected

**Podman**:
- Native multi-architecture support
- No additional setup required
- Drop-in replacement for Docker commands
- Rootless container support

**Auto-Detection**:
The Makefile automatically detects which container engine is available and uses it. You can also explicitly specify:

```bash
# Use Docker
CONTAINER_ENGINE=docker make build

# Use Podman
CONTAINER_ENGINE=podman make build
```

### Open Horizon Exchange API

Agents can interact with the Open Horizon Exchange API for automation:

**Base URL**: `https://<hub-host>/edge-exchange/v1`

**Authentication**: Basic Auth with `HZN_EXCHANGE_USER_AUTH`

**Common Endpoints**:

```bash
# List services
GET /orgs/{org}/services

# Get service details
GET /orgs/{org}/services/{service}

# Publish service
POST /orgs/{org}/services

# List patterns
GET /orgs/{org}/patterns

# List nodes
GET /orgs/{org}/nodes

# Get node status
GET /orgs/{org}/nodes/{node}
```

**Example Agent API Call**:

```python
import requests
from requests.auth import HTTPBasicAuth
import subprocess

# Detect container engine
def get_container_engine():
    for engine in ['docker', 'podman']:
        try:
            subprocess.run([engine, '--version'], 
                         capture_output=True, check=True)
            return engine
        except (subprocess.CalledProcessError, FileNotFoundError):
            continue
    return 'docker'  # default

container_engine = get_container_engine()
print(f"Using container engine: {container_engine}")

# Configuration
hub_host = "your-hub-host"
org_id = "your-org"
auth = HTTPBasicAuth("username", "token")

# List services
response = requests.get(
    f"https://{hub_host}/edge-exchange/v1/orgs/{org_id}/services",
    auth=auth
)

services = response.json()
print(f"Found {len(services)} services")
```

### Service Health Check

**Endpoint**: `http://localhost:8080/health`

**Method**: GET

**Response**: 200 OK if service is healthy

**Example Agent Health Check**:

```python
import requests

def check_service_health():
    try:
        response = requests.get("http://localhost:8080/health", timeout=5)
        return response.status_code == 200
    except requests.RequestException:
        return False

if check_service_health():
    print("Service is healthy")
else:
    print("Service is not responding")
```

## Example Agent Prompts

### For LLM Agents

**Deployment Assistance**:
```
"Help me deploy the Open Horizon nginx service to my Raspberry Pi 4 
with the message 'Welcome to my IoT device'"
```

**Troubleshooting**:
```
"My nginx service shows 'agreement not formed' status. 
Here's my hzn eventlog output: [paste output]"
```

**Customization**:
```
"Modify this service to serve content from a mounted volume 
instead of the built-in HTML"
```

**Documentation**:
```
"Explain how the userInput variable 'message' flows from 
registration to the displayed web page"
```

### For Automation Agents

**CI/CD Pipeline**:
```yaml
# GitHub Actions example - Docker
name: Build and Publish Service (Docker)
on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1
      
      - name: Build and push
        run: |
          make build-all-arches
          make push
          make publish-service

# GitHub Actions example - Podman
name: Build and Publish Service (Podman)
on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install Podman
        run: |
          sudo apt-get update
          sudo apt-get -y install podman
      
      - name: Build and push
        run: |
          CONTAINER_ENGINE=podman make build-all-arches
          CONTAINER_ENGINE=podman make push
          make publish-service
```

**Monitoring Script**:
```bash
#!/bin/bash
# Monitor service health and restart if needed
# Works with both Docker and Podman

# Detect container engine
if command -v docker &> /dev/null; then
    CONTAINER_ENGINE="docker"
elif command -v podman &> /dev/null; then
    CONTAINER_ENGINE="podman"
else
    echo "Error: Neither docker nor podman found"
    exit 1
fi

echo "Using container engine: $CONTAINER_ENGINE"

while true; do
  if ! curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "Service unhealthy, restarting..."
    hzn unregister -f
    hzn register -p pattern-service-nginx
  fi
  sleep 60
done
```

## Security Considerations for Agents

### Authentication

- **Never hardcode credentials** in agent code
- Use environment variables or secure vaults
- Rotate credentials regularly
- Use least-privilege access

### Input Validation

- **Sanitize user inputs** before passing to commands
- Validate userInput variables
- Prevent command injection
- Escape special characters

### API Security

- **Use HTTPS** for all API calls
- Verify SSL certificates
- Implement rate limiting
- Log all API interactions

### Example Secure Agent Code

```python
import os
import shlex
from typing import Optional

class SecureOpenHorizonAgent:
    def __init__(self):
        # Get credentials from environment
        self.org_id = os.getenv('HZN_ORG_ID')
        self.auth = os.getenv('HZN_EXCHANGE_USER_AUTH')
        
        if not self.org_id or not self.auth:
            raise ValueError("Missing required credentials")
    
    def sanitize_message(self, message: str) -> str:
        """Sanitize user message input"""
        # Remove potentially dangerous characters
        safe_message = message.replace('"', '\\"')
        safe_message = safe_message.replace('$', '\\$')
        safe_message = safe_message.replace('`', '\\`')
        return safe_message
    
    def deploy_service(self, message: str) -> bool:
        """Deploy service with sanitized message"""
        safe_message = self.sanitize_message(message)
        
        # Use shlex for safe command construction
        cmd = shlex.split(f'hzn register -p pattern-service-nginx')
        cmd.extend(['-i', f'message={safe_message}'])
        
        # Execute safely
        # ... implementation
        return True
```

## Agent Development Best Practices

### 1. Error Handling

- Implement comprehensive error handling
- Provide clear error messages
- Log errors for debugging
- Offer recovery suggestions

### 2. User Feedback

- Provide progress updates
- Explain what the agent is doing
- Confirm successful operations
- Ask for clarification when needed

### 3. Idempotency

- Design operations to be repeatable
- Check current state before acting
- Handle partial failures gracefully
- Support rollback operations

### 4. Testing

- Test with multiple architectures
- Validate edge cases
- Test error conditions
- Verify security measures

### 5. Documentation

- Document agent capabilities
- Provide usage examples
- Explain limitations
- Keep documentation updated

## Future Enhancements

### Planned Agent Capabilities

1. **Autonomous Service Updates**
   - Detect new service versions
   - Perform rolling updates
   - Rollback on failure

2. **Predictive Maintenance**
   - Analyze service metrics
   - Predict failures
   - Proactive remediation

3. **Multi-Service Orchestration**
   - Coordinate multiple services
   - Manage dependencies
   - Optimize resource usage

4. **Natural Language Interface**
   - Voice-activated deployment
   - Conversational troubleshooting
   - Interactive configuration

5. **Learning and Adaptation**
   - Learn from deployment patterns
   - Optimize configurations
   - Suggest improvements

## Contributing Agent Integrations

We welcome contributions of new agent integrations! Please:

1. Follow the patterns documented here
2. Implement proper security measures
3. Provide comprehensive examples
4. Document your integration
5. Submit a pull request

See [CONTRIBUTORS.md](CONTRIBUTORS.md) for contribution guidelines.

## Support

For agent integration questions:

- **GitHub Issues**: [Report issues](https://github.com/joewxboy/service-nginx/issues)
- **Email**: joe.pearson@us.ibm.com
- **Community**: [Open Horizon Slack](https://lfedge.slack.com/)

## Resources

- [Open Horizon API Documentation](https://github.com/open-horizon/anax/blob/master/doc/api.md)
- [Open Horizon CLI Reference](https://github.com/open-horizon/anax/blob/master/cli/README.md)
- [Docker API Documentation](https://docs.docker.com/engine/api/)
- [LangChain for Agent Development](https://python.langchain.com/)

## License

This documentation is part of the service-nginx project and is licensed under the Apache License 2.0.
