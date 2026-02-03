# Issue: One-Click Docker Deployment for OpenClaw

**Title:** Docker Image: Create one-click deployable OpenClaw container with pre-configured setup

**Type:** Feature Request / Infrastructure

**Priority:** High

---

## 📝 Summary

Create a production-ready Docker image for OpenClaw that enables one-click deployment without manual configuration. Based on Simon Willison's guide and official documentation, the image should simplify the setup process and make OpenClaw accessible to non-technical users.

## 🎯 Objectives

1. **Official Docker Image**: Publish to Docker Hub for easy `docker pull`
2. **Pre-configured Defaults**: Include common model providers (Zhipu, OpenAI, etc.)
3. **Environment-based Config**: Use ENV variables for all settings
4. **Multi-platform Support**: amd64, arm64 (Apple Silicon, Raspberry Pi)
5. **Persistent Volumes**: Easy data and configuration mounting
6. **Health Checks**: Built-in container health monitoring
7. **Quick Start**: One-command launch experience

## 📋 Reference Documentation

Based on Simon Willison's Docker setup guide:
- **Article:** https://til.simonwillison.net/llms/openclaw-docker
- **Official Docs:** https://docs.openclaw.ai/install/docker

**Key Coverage:**
- Docker Compose setup with docker-setup.sh
- Volume mounting strategy (~/.openclaw, ~/openclaw/workspace)
- First-run onboarding wizard
- Common pitfalls and workarounds
- Telegram bot integration
- Dashboard authentication

## ✨ Proposed Features

### Phase 1: Core Image
- [ ] Multi-stage Dockerfile optimization
- [ ] Base image selection (node:22-alpine vs node:22-slim)
- [ ] OpenClauw installation baked in
- [ ] Health check endpoint
- [ ] Default volume paths

### Phase 2: Environment Configuration
- [ ] ENV-based configuration system
- [ ] Support for multiple model providers:
  - `ZHIPU_API_KEY` - Zhipu AI
  - `OPENAI_API_KEY` - OpenAI
  - `ANTHROPIC_API_KEY` - Claude
  - `COHERE_API_KEY` - Cohere
- [ ] Gateway token auto-generation
- [ ] Default model selection
- [ ] Gateway mode configuration (local/remote)

### Phase 3: Communication Channels
- [ ] Pre-configured Telegram bot setup
- [ ] Environment variables for channels:
  - `TELEGRAM_BOT_TOKEN`
  - `WHATSAPP_PHONE_ID`
  - `SLACK_BOT_TOKEN`
  - `DISCORD_BOT_TOKEN`
- [ ] Auto-pairing mechanism

### Phase 4: Developer Experience
- [ ] docker-compose.yml with comments
- [ ] Quick start guide (README in image)
- [ ] Example .env file
- [ ] Init script for first-run setup
- [ ] Migration guide from bare metal

### Phase 5: Production Ready
- [ ] Multi-architecture builds (amd64, arm64)
- [ ] Security scanning (Trivy, Snyk)
- [ ] Minimal image size (< 500MB)
- [ ] Non-root user support
- [ ] Signal handling for graceful shutdown

## 🔧 Technical Implementation

### Dockerfile Structure

```dockerfile
# Multi-stage build
FROM node:22-alpine AS builder
WORKDIR /app
RUN npm install -g openclaw@latest

FROM node:22-alpine
RUN apk add --no-cache git curl
COPY --from=builder /usr/local/lib/node_modules/openclaw /usr/local/lib/node_modules/openclaw
RUN ln -s /usr/local/lib/node_modules/openclaw/dist/index.js /usr/local/bin/openclaw

# Setup directories
RUN mkdir -p /root/.openclaw /workspace
VOLUME ["/root/.openclaw", "/workspace"]

# Environment defaults
ENV GATEWAY_MODE=local
ENV GATEWAY_BIND=0.0.0.0
ENV GATEWAY_PORT=18789
ENV OPENCLAW_MODEL=zhipu/GLM-4.7

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:18789/health || exit 1

EXPOSE 18789
CMD ["gateway"]
```

### Docker Compose Template

```yaml
version: '3.8'

services:
  openclaw:
    image: openclaw/openclaw:latest
    container_name: openclaw-gateway
    restart: unless-stopped
    ports:
      - "18789:18789"
    environment:
      # Model Provider (choose one)
      - ZHIPU_API_KEY=${ZHIPU_API_KEY}
      # - OPENAI_API_KEY=${OPENAI_API_KEY}

      # Gateway Config
      - GATEWAY_MODE=local
      - GATEWAY_TOKEN=${GATEWAY_TOKEN:-auto}

      # Default Model
      - OPENCLAW_MODEL=zhipu/GLM-4.7

      # Telegram (optional)
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}

    volumes:
      # Persist configuration and memory
      - openclaw-data:/root/.openclaw
      # Workspace for agent files
      - ./workspace:/workspace
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18789/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  openclaw-data:
    driver: local
```

### Quick Start Experience

```bash
# 1. Pull image
docker pull openclaw/openclaw:latest

# 2. Create .env file
cat > .env << EOF
ZHIPU_API_KEY=your_api_key_here
GATEWAY_TOKEN=secure_token_here
TELEGRAM_BOT_TOKEN=your_bot_token
EOF

# 3. Launch
docker run -d \
  --name openclaw \
  -p 18789:18789 \
  --env-file .env \
  -v openclaw-data:/root/.openclaw \
  -v $(pwd)/workspace:/workspace \
  openclaw/openclaw:latest

# 4. Access dashboard
open http://localhost:18789?token=secure_token_here
```

## 📊 User Experience Flow

```
User: docker run -d openclaw/openclaw
       ↓
Container: Checks ENV variables
       ↓
Container: No ZHIPU_API_KEY found
       ↓
Container: Logs error message
       ↓
User: docker run -d -e ZHIPU_API_KEY=... openclaw/openclaw
       ↓
Container: Validates API key
       ↓
Container: Starts gateway
       ↓
Container: Prints setup URL
       ↓
User: Opens http://localhost:18789?token=...
       ↓
User: Configures Telegram bot
       ↓
User: Done! Ready to chat
```

## 🎯 Success Criteria

- [ ] Image builds successfully on multiple architectures
- [ ] Can run with single `docker run` command
- [ ] Environment variables override all settings
- [ ] Data persists across container restarts
- [ ] Health checks work correctly
- [ ] Image size < 500MB compressed
- [ ] Security scan passes (no critical vulnerabilities)
- [ ] Documentation is clear and comprehensive
- [ ] Works with Docker Compose out of the box

## 🔧 Build & Publishing

### GitHub Actions Workflow

```yaml
name: Build and Push Docker Image

on:
  push:
    tags:
      - 'v*'
    branches:
      - main
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            openclaw/openclaw:latest
            openclaw/openclaw:${{ github.ref_name }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: openclaw/openclaw:latest
          format: 'sarif'
          output: 'trivy-results.sarif'
```

## 🔗 Related Issues

- Auto-Deployment Skill: https://github.com/alijiujiu123/openclaw/issues/1
- Installation Guide: https://github.com/alijiujiu123/openclaw/commit/2e3982f68
- Simon's Guide: https://til.simonwillison.net/llms/openclaw-docker

## 📅 Tasks

1. Create optimized Dockerfile
2. Setup GitHub Actions for multi-arch builds
3. Create docker-compose.yml template
4. Write comprehensive documentation
5. Create quick start guide
6. Add health check implementation
7. Implement environment variable system
8. Add volume mounting strategy
9. Create .env.example file
10. Test on multiple platforms
11. Security scanning integration
12. Publish to Docker Hub
13. Create release notes
14. Write migration guide

## 💡 Future Enhancements

- **Kubernetes Helm Chart**: Deploy to K8s clusters
- **Cloud Marketplace Images**: AWS Marketplace, Google Cloud Marketplace
- **Auto-updates**: Watch for new OpenClaw releases
- **Metrics Export**: Prometheus metrics endpoint
- **Plugin System**: Easy feature toggle via ENV
- **Configuration UI**: Web-based config generator
- **Backup/Restore**: Automated volume snapshot tools
- **Multi-instance Mode**: Run multiple OpenClaw instances

## 🐛 Known Issues from Simon's Guide

- Dashboard token authentication requires manual URL construction
- Telegram bot pairing requires CLI command outside container
- First-run wizard can be confusing
- Service discovery for remote gateway mode needs documentation

---

**Label:** `enhancement` `docker` `infrastructure` `good-first-issue`

**Assignees:** @openclaw/community

**Milestone:** v1.0
