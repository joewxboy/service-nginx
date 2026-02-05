# Open Horizon Nginx Service - Implementation Plan

## Project Overview

Create a multi-architecture Open Horizon edge service that serves a simple web page using the latest nginx container. The service will support both arm64 and amd64 architectures and display a customizable message via a userInput variable.

## Maintainer Information

- **Name**: Joe Pearson
- **Email**: joe.pearson@us.ibm.com
- **GitHub**: @joewxboy
- **Organization**: IBM

## Architecture

### Multi-Architecture Support
- **amd64** (x86_64): Standard Linux servers and desktops
- **arm64** (aarch64): ARM-based devices (Raspberry Pi 4, NVIDIA Jetson, etc.)

### Service Components

```
service-nginx/
├── Dockerfile                    # Multi-arch nginx container
├── service.json                  # Open Horizon service definition
├── Makefile                      # Build and publish automation
├── horizon/
│   ├── pattern.json             # Deployment pattern
│   ├── policy.json              # Deployment policy
│   └── userinput.json           # Example user input configuration
├── nginx/
│   ├── nginx.conf               # Custom nginx configuration
│   └── html/
│       └── index.html           # Web page template with message variable
├── scripts/
│   ├── entrypoint.sh            # Container startup script
│   └── test-service.sh          # Local testing script
├── README.md                     # Main documentation
├── AGENTS.md                     # AI agent interaction documentation
├── MAINTAINERS.md               # Maintainer information
├── CONTRIBUTORS.md              # Contributor guidelines
├── LICENSE                       # Apache-2.0 license
└── .gitignore                   # Git ignore patterns
```

## Implementation Details

### 1. Dockerfile (Multi-arch)

**Base Image**: `nginx:latest` (official nginx image with multi-arch support)

**Key Features**:
- Use official nginx base image (supports multiple architectures)
- Copy custom nginx configuration
- Copy HTML template
- Add entrypoint script to substitute environment variables
- Expose port 80
- Health check endpoint

**Environment Variables**:
- `MESSAGE`: User-configurable message (default: "Hello from Open Horizon!")

### 2. Service Definition (service.json)

**Structure**:
```json
{
  "org": "$HZN_ORG_ID",
  "label": "Nginx Web Server",
  "description": "Simple nginx web server with customizable message",
  "public": true,
  "documentation": "https://github.com/joewxboy/service-nginx",
  "url": "service-nginx",
  "version": "1.0.0",
  "arch": "$ARCH",
  "sharable": "multiple",
  "requiredServices": [],
  "userInput": [
    {
      "name": "message",
      "label": "Display Message",
      "type": "string",
      "defaultValue": "Hello from Open Horizon!"
    }
  ],
  "deployment": {
    "services": {
      "nginx": {
        "image": "${DOCKER_IMAGE_BASE}_$ARCH:$SERVICE_VERSION",
        "environment": [
          "MESSAGE=$message"
        ],
        "ports": [
          {
            "HostPort": "8080:80/tcp",
            "HostIP": "0.0.0.0"
          }
        ]
      }
    }
  }
}
```

### 3. Nginx Configuration

**nginx.conf**:
- Simple HTTP server configuration
- Serve static content from /usr/share/nginx/html
- Access and error logging
- Health check endpoint at /health

**index.html**:
- Simple HTML page with placeholder for MESSAGE
- Responsive design
- Display architecture information
- Show timestamp

### 4. Entrypoint Script

**Purpose**: Substitute environment variables into HTML template at runtime

**Process**:
1. Read MESSAGE environment variable
2. Use `envsubst` to replace placeholders in index.html
3. Start nginx in foreground

### 5. Makefile

**Targets**:
- `build`: Build Docker images for both architectures
- `build-amd64`: Build amd64 image
- `build-arm64`: Build arm64 image
- `push`: Push images to Docker registry
- `publish-service`: Publish service definition to Open Horizon Exchange
- `publish-pattern`: Publish deployment pattern
- `publish-policy`: Publish deployment policy
- `test`: Run local container for testing
- `clean`: Remove local images and artifacts
- `help`: Display available targets

**Variables**:
- `DOCKER_REGISTRY`: Docker registry URL
- `DOCKER_IMAGE_BASE`: Base image name
- `SERVICE_VERSION`: Service version
- `HZN_ORG_ID`: Open Horizon organization ID

### 6. Horizon Configuration Files

**pattern.json**:
- Define deployment pattern for the service
- Specify service constraints
- Set default user input values

**policy.json**:
- Define deployment policy
- Specify node constraints (architecture, properties)
- Set service rollback configuration

**userinput.json**:
- Example user input configuration
- Template for node registration

### 7. Documentation Files

#### README.md
**Sections**:
1. Overview and description
2. Prerequisites (Docker, Open Horizon CLI, account)
3. Quick Start
4. Building the Service
   - Local Docker build
   - Multi-arch build with buildx
5. Publishing to Open Horizon
   - Service publication
   - Pattern publication
   - Policy publication
6. Deploying the Service
   - Register node with pattern
   - Register node with policy
   - Verify deployment
7. Testing
   - Local testing with Docker
   - Edge node testing
8. Configuration
   - UserInput variables
   - Environment variables
9. Troubleshooting
10. Contributing
11. License

#### AGENTS.md
**Sections**:
1. Overview of AI agent capabilities
2. Supported Agent Types
   - LLM-based agents (ChatGPT, Claude, etc.)
   - Automation agents (GitHub Copilot, etc.)
3. Agent Interaction Patterns
   - Service deployment
   - Configuration management
   - Monitoring and troubleshooting
4. API Endpoints for Agents
5. Example Agent Prompts
6. Security Considerations
7. Future Enhancements

#### MAINTAINERS.md
**Content**:
- Project maintainer: Joe Pearson
- Contact information
- Responsibilities
- Decision-making process
- How to become a maintainer

#### CONTRIBUTORS.md
**Sections**:
1. How to Contribute
2. Code of Conduct
3. Development Setup
4. Coding Standards
5. Testing Requirements
6. Pull Request Process
7. Issue Reporting
8. Community Guidelines
9. Recognition of Contributors

### 8. Additional Files

**LICENSE**:
- Apache License 2.0 (standard for Open Horizon projects)

**.gitignore**:
- Docker build artifacts
- Horizon credentials
- Local test files
- IDE configurations

## Build Process

### Local Development
1. Build Docker image locally
2. Test with docker run
3. Verify web page displays correctly
4. Test with different MESSAGE values

### Multi-Architecture Build
1. Set up Docker buildx
2. Create multi-arch builder
3. Build and push for both architectures
4. Verify manifest includes both architectures

### Open Horizon Publication
1. Set environment variables (HZN_ORG_ID, HZN_EXCHANGE_USER_AUTH)
2. Build and push Docker images
3. Publish service definition
4. Publish pattern or policy
5. Verify in Exchange

## Deployment Process

### Pattern-Based Deployment
1. Register node with pattern
2. Provide user input values
3. Verify service starts
4. Test web page access

### Policy-Based Deployment
1. Create deployment policy
2. Register node with policy
3. Verify service deployment
4. Monitor service status

## Testing Strategy

### Unit Testing
- Dockerfile builds successfully
- Nginx configuration is valid
- HTML template renders correctly
- Environment variable substitution works

### Integration Testing
- Service registers with Exchange
- Service deploys to edge node
- Web page is accessible
- Message displays correctly
- Multi-arch images work on respective platforms

### End-to-End Testing
1. Build service
2. Publish to Exchange
3. Deploy to test node (amd64)
4. Deploy to test node (arm64)
5. Verify functionality on both architectures
6. Test with different user input values

## Security Considerations

1. **Container Security**:
   - Use official nginx base image
   - Regular security updates
   - Minimal attack surface

2. **Network Security**:
   - Expose only necessary ports
   - Consider TLS/SSL for production

3. **Access Control**:
   - Proper Open Horizon authentication
   - Service signing for production

4. **Input Validation**:
   - Sanitize MESSAGE input
   - Prevent XSS attacks

## Success Criteria

- [ ] Multi-arch Docker images build successfully
- [ ] Service definition is valid
- [ ] Service publishes to Open Horizon Exchange
- [ ] Service deploys on amd64 edge node
- [ ] Service deploys on arm64 edge node
- [ ] Web page displays custom message
- [ ] All documentation files are complete
- [ ] README provides clear instructions
- [ ] AGENTS.md documents AI interaction patterns
- [ ] MAINTAINERS.md lists Joe Pearson
- [ ] CONTRIBUTORS.md follows Open Horizon standards

## Timeline Estimate

1. **Setup and Configuration** (30 minutes)
   - Create directory structure
   - Set up Dockerfile and nginx config

2. **Service Implementation** (1 hour)
   - Create service.json
   - Write entrypoint script
   - Create HTML template
   - Write Makefile

3. **Horizon Configuration** (30 minutes)
   - Create pattern.json
   - Create policy.json
   - Create userinput.json

4. **Documentation** (1.5 hours)
   - Write README.md
   - Write AGENTS.md
   - Write MAINTAINERS.md
   - Write CONTRIBUTORS.md

5. **Testing and Validation** (1 hour)
   - Local testing
   - Multi-arch build testing
   - Documentation review

**Total Estimated Time**: 4 hours

## Next Steps

1. Review and approve this plan
2. Switch to 'code' mode to implement the service
3. Create all necessary files following this plan
4. Test locally before publishing
5. Publish to Open Horizon Exchange
6. Deploy and verify on edge nodes

## References

- Open Horizon Documentation: https://open-horizon.github.io/
- Open Horizon Examples: https://github.com/open-horizon/examples
- Nginx Official Documentation: https://nginx.org/en/docs/
- Docker Multi-arch Builds: https://docs.docker.com/build/building/multi-platform/
