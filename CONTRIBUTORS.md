# Contributing to Open Horizon Nginx Service

Thank you for your interest in contributing to the Open Horizon Nginx Service! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Community Guidelines](#community-guidelines)
- [Recognition](#recognition)

## Code of Conduct

This project follows the [LF Edge Code of Conduct](https://lfprojects.org/policies/code-of-conduct/). By participating, you are expected to uphold this code. Please report unacceptable behavior to joe.pearson@us.ibm.com.

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of:
- Age, body size, disability, ethnicity
- Gender identity and expression
- Level of experience, education
- Nationality, personal appearance, race, religion
- Sexual identity and orientation

### Our Standards

**Positive behaviors include:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards others

**Unacceptable behaviors include:**
- Trolling, insulting/derogatory comments, personal or political attacks
- Public or private harassment
- Publishing others' private information without permission
- Other conduct which could reasonably be considered inappropriate

## How to Contribute

### Types of Contributions

We welcome many types of contributions:

1. **Code Contributions**
   - Bug fixes
   - New features
   - Performance improvements
   - Multi-architecture support enhancements

2. **Documentation**
   - README improvements
   - API documentation
   - Tutorials and examples
   - Translation

3. **Testing**
   - Bug reports
   - Test case additions
   - Multi-platform testing

4. **Community**
   - Answering questions
   - Reviewing pull requests
   - Participating in discussions

### Getting Started

1. **Fork the Repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/service-nginx.git
   cd service-nginx
   ```

2. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/joewxboy/service-nginx.git
   ```

3. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

4. **Make Your Changes**
   - Write clear, concise code
   - Follow coding standards
   - Add tests if applicable
   - Update documentation

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Description of your changes"
   ```

6. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your branch
   - Fill out the PR template

## Development Setup

### Prerequisites

- **Docker**: Version 20.10 or later
- **Docker Buildx**: For multi-architecture builds
- **Open Horizon CLI**: `hzn` command-line tool
- **Git**: Version control
- **Make**: Build automation
- **Text Editor**: VS Code, vim, or your preference

### Environment Setup

1. **Install Docker**
   ```bash
   # macOS
   brew install docker
   
   # Ubuntu/Debian
   sudo apt-get install docker.io
   
   # Verify installation
   docker --version
   ```

2. **Install Open Horizon CLI**
   ```bash
   # Follow instructions at:
   # https://github.com/open-horizon/anax/releases
   
   # Verify installation
   hzn version
   ```

3. **Set Up Docker Buildx**
   ```bash
   docker buildx create --name multiarch --use
   docker buildx inspect --bootstrap
   ```

4. **Configure Environment Variables**
   ```bash
   export HZN_ORG_ID=your-org-id
   export HZN_EXCHANGE_USER_AUTH=your-username:your-token
   export DOCKER_REGISTRY=docker.io/yourusername
   ```

### Local Development

1. **Build the Service**
   ```bash
   make build
   ```

2. **Test Locally**
   ```bash
   make test
   ```

3. **View Logs**
   ```bash
   docker logs $(docker ps -q --filter ancestor=service-nginx)
   ```

4. **Clean Up**
   ```bash
   make clean
   ```

## Coding Standards

### General Guidelines

- **Clarity**: Write clear, readable code
- **Simplicity**: Keep it simple and maintainable
- **Documentation**: Comment complex logic
- **Consistency**: Follow existing patterns

### Dockerfile Standards

```dockerfile
# Use official base images
FROM nginx:latest

# Add labels for metadata
LABEL maintainer="joe.pearson@us.ibm.com"
LABEL version="1.0.0"

# Copy files with clear purpose
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/html /usr/share/nginx/html

# Use COPY instead of ADD unless you need tar extraction
# Group related commands to reduce layers
RUN apt-get update && \
    apt-get install -y gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Expose ports explicitly
EXPOSE 80

# Use exec form for ENTRYPOINT
ENTRYPOINT ["/scripts/entrypoint.sh"]
```

### Shell Script Standards

```bash
#!/bin/bash
# Script description and purpose

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Use meaningful variable names
readonly MESSAGE="${MESSAGE:-Hello from Open Horizon!}"

# Function documentation
# Substitutes environment variables in HTML template
substitute_variables() {
    local template="$1"
    local output="$2"
    
    envsubst < "$template" > "$output"
}

# Main execution
main() {
    substitute_variables "/template/index.html" "/usr/share/nginx/html/index.html"
    exec nginx -g 'daemon off;'
}

main "$@"
```

### JSON Standards

```json
{
  "org": "$HZN_ORG_ID",
  "label": "Descriptive Label",
  "description": "Clear description of purpose",
  "version": "1.0.0",
  "arch": "$ARCH",
  "userInput": [
    {
      "name": "message",
      "label": "Display Message",
      "type": "string",
      "defaultValue": "Hello from Open Horizon!"
    }
  ]
}
```

### Makefile Standards

```makefile
# Variables at the top
DOCKER_REGISTRY ?= docker.io/yourusername
SERVICE_VERSION ?= 1.0.0

# Phony targets
.PHONY: build push clean help

# Default target
.DEFAULT_GOAL := help

# Help target with descriptions
help: ## Display this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Build target with clear steps
build: ## Build Docker image
	docker build -t $(DOCKER_REGISTRY)/service-nginx:$(SERVICE_VERSION) .
```

## Testing Requirements

### Before Submitting

1. **Build Tests**
   ```bash
   # Test build for current architecture
   make build
   
   # Test multi-arch build
   make build-all-arches
   ```

2. **Functional Tests**
   ```bash
   # Start service locally
   make test
   
   # Verify web page
   curl http://localhost:8080
   
   # Check with custom message
   docker run -e MESSAGE="Test" -p 8080:80 service-nginx:1.0.0
   ```

3. **Documentation Tests**
   ```bash
   # Verify all links work
   # Check code examples execute correctly
   # Ensure README is up-to-date
   ```

### Test Coverage

- All new features must include tests
- Bug fixes should include regression tests
- Multi-architecture changes must be tested on both platforms
- Documentation changes should be verified

## Pull Request Process

### PR Checklist

Before submitting a pull request, ensure:

- [ ] Code builds successfully
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] Branch is up-to-date with main
- [ ] No merge conflicts
- [ ] PR description is complete

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Other (please describe)

## Testing
Describe testing performed

## Checklist
- [ ] Code builds successfully
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Follows coding standards

## Related Issues
Fixes #(issue number)
```

### Review Process

1. **Automated Checks**
   - Build verification
   - Linting
   - Basic tests

2. **Maintainer Review**
   - Code quality
   - Design decisions
   - Documentation
   - Test coverage

3. **Feedback and Iteration**
   - Address review comments
   - Update as needed
   - Re-request review

4. **Merge**
   - Approved by maintainer
   - All checks pass
   - Squash and merge

### Commit Message Guidelines

Use clear, descriptive commit messages:

```
Short summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain what and why, not how.

- Bullet points are okay
- Use present tense: "Add feature" not "Added feature"
- Reference issues: "Fixes #123"
```

**Examples:**
```
Add support for custom nginx configuration

Allow users to provide their own nginx.conf file through
a mounted volume. This enables advanced configurations
without rebuilding the container.

Fixes #42
```

## Issue Reporting

### Bug Reports

Use the bug report template:

```markdown
**Describe the bug**
Clear description of the issue

**To Reproduce**
Steps to reproduce:
1. Step one
2. Step two
3. See error

**Expected behavior**
What should happen

**Environment**
- OS: [e.g., Ubuntu 20.04]
- Architecture: [e.g., amd64, arm64]
- Docker version: [e.g., 20.10.12]
- Open Horizon version: [e.g., 2.30.0]

**Additional context**
Any other relevant information
```

### Feature Requests

Use the feature request template:

```markdown
**Is your feature request related to a problem?**
Description of the problem

**Describe the solution you'd like**
Clear description of desired functionality

**Describe alternatives you've considered**
Other approaches you've thought about

**Additional context**
Any other relevant information
```

## Community Guidelines

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **Pull Requests**: Code contributions and reviews
- **Discussions**: General questions and ideas
- **Slack**: Real-time chat ([LF Edge Slack](https://lfedge.slack.com/))
- **Email**: joe.pearson@us.ibm.com

### Best Practices

1. **Be Respectful**
   - Treat everyone with respect
   - Assume good intentions
   - Provide constructive feedback

2. **Be Clear**
   - Write clear descriptions
   - Provide context
   - Include examples

3. **Be Patient**
   - Maintainers are volunteers
   - Reviews take time
   - Be understanding

4. **Be Helpful**
   - Answer questions
   - Review others' PRs
   - Share knowledge

## Recognition

### Contributors

All contributors are recognized in:
- GitHub contributors page
- Release notes
- Project documentation

### Significant Contributions

Contributors with significant impact may be:
- Invited to become maintainers
- Recognized in project announcements
- Featured in community highlights

### Hall of Fame

We maintain a list of notable contributors:
- First-time contributors
- Regular contributors
- Major feature contributors
- Documentation champions

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0, the same license as the project.

## Questions?

If you have questions about contributing:

- **Open an Issue**: For general questions
- **Email**: joe.pearson@us.ibm.com
- **Slack**: Join [LF Edge Slack](https://lfedge.slack.com/)

## Thank You!

Thank you for contributing to the Open Horizon Nginx Service! Your contributions help make edge computing more accessible and powerful.

---

*Last Updated: 2026-02-04*
