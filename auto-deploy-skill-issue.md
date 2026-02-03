# Issue: Create Auto-Deployment Skill for OpenClaw

**Title:** Auto-Deployment Skill: Automate OpenClaw installation based on installation guide

**Type:** Feature Request / Skill Development

**Priority:** High

---

## 📝 Summary

Create an OpenClaw skill that automates the complete installation and configuration process documented in `docs/installation-guide.md`. The skill should guide users through deploying OpenClaw on various Linux distributions (OpenCloudOS/RHEL/CentOS/Ubuntu) with minimal manual intervention.

## 🎯 Objectives

1. **Automated Server Setup**: Detect OS, check prerequisites, install dependencies
2. **Interactive Configuration**: Guide users through API key setup, gateway config, model selection
3. **Error Recovery**: Detect and handle common pitfalls (10+ documented in the guide)
4. **Verification**: Run validation checks at each step
5. **Multi-Cloud Support**: Support DigitalOcean, Vultr, Linode, etc.

## 📋 Reference Documentation

Based on comprehensive installation guide:
- **Commit:** https://github.com/alijiujiu123/openclaw/commit/2e3982f68
- **Coverage:**
  - OpenCloudOS 9.2 / DigitalOcean deployment
  - Zhipu AI GLM-4.7 model configuration
  - 10+ common pitfalls and solutions
  - systemd service configuration
  - SSH tunnel and dashboard access
  - Complete verification checklist

## ✨ Proposed Skill Features

### Phase 1: Pre-Flight Checks
- [ ] Detect OS and version (`cat /etc/os-release`, `uname -a`)
- [ ] Check Node.js version (require 22+)
- [ ] Verify available disk space (min 10GB)
- [ ] Check RAM (min 1GB, recommend 2GB+)
- [ ] Test network connectivity

### Phase 2: Automated Installation
- [ ] Install Node.js 22 if missing (handle multiple distros)
- [ ] Run OpenClaw installer script
- [ ] Fix directory permissions (`chmod 700 ~/.openclaw`)
- [ ] Create required directories automatically
- [ ] Configure systemd service

### Phase 3: Interactive Configuration Wizard
- [ ] Gateway mode selection (local/remote)
- [ ] Auth token generation
- [ ] Model provider selection:
  - Zhipu AI (GLM-4.7/4.6/4.5-air)
  - OpenAI (GPT-4/Claude/etc.)
  - Other providers
- [ ] API key collection and validation
- [ ] Configuration file generation

### Phase 4: Service Management
- [ ] Start Gateway service
- [ ] Enable auto-start on boot
- [ ] Verify service status
- [ ] Display logs if startup fails

### Phase 5: Post-Install Setup
- [ ] Generate SSH tunnel command
- [ ] Create dashboard URL with token
- [ ] Test dashboard connectivity
- [ ] Optional: Telegram bot setup
- [ ] Optional: Channel configuration

### Phase 6: Troubleshooting & Diagnostics
- [ ] Run comprehensive verification checklist
- [ ] Detect and fix common issues:
  - Missing tokens
  - Wrong permissions
  - Port conflicts
  - Network issues
- [ ] Provide helpful error messages
- [ ] Offer auto-fix when possible

## 🔧 Technical Implementation

### Skill Structure
```
skills/
├── auto-deploy/
│   ├── SKILL.md              # Main skill documentation
│   ├── README.md             # User-facing documentation
│   ├── lib/
│   │   ├── detector.js       # OS/environment detection
│   │   ├── installer.js      # Installation automation
│   │   ├── configurator.js   # Configuration wizard
│   │   ├── validator.js      # Verification & checks
│   │   └── troubleshooter.js # Common issues & fixes
│   ├── templates/
│   │   ├── openclaw.json    # Configuration templates
│   │   └── systemd.service  # Service file templates
│   └── tests/
│       └── auto-deploy.test.js
```

### Key Functions
- `detectEnvironment()` - Gather system info
- `checkPrerequisites()` - Verify requirements
- `installNodejs()` - Handle Node.js installation
- `installOpenClaw()` - Run installer
- `configureGateway()` - Setup gateway auth
- `configureModel()` - Setup model provider
- `startService()` - Enable and start systemd
- `verifyInstallation()` - Run checks
- `generateInstructions()` - Output next steps

## 📊 User Experience Flow

```
User: "Help me install OpenClaw on my server"
       ↓
Skill: Runs pre-flight checks
       ↓
Skill: "I detected Ubuntu 22.04. Node.js is not installed.
       Should I install Node.js 22? (y/n)"
       ↓
User: "y"
       ↓
Skill: Installs Node.js, then OpenClaw
       ↓
Skill: "Which model provider do you want to use?
       1. Zhipu AI (GLM-4.7)
       2. OpenAI (GPT-4)
       3. Other"
       ↓
User: "1"
       ↓
Skill: "Please enter your Zhipu API Key:"
       ↓
User: [pastes API key]
       ↓
Skill: Configures everything, starts service
       ↓
Skill: "✓ Installation complete!
       Dashboard: http://localhost:8888?token=...
       SSH tunnel: ssh -L 8888:localhost:18789 root@..."
```

## 🎯 Success Criteria

- [ ] Skill can complete installation on fresh servers
- [ ] Handles all 10+ documented pitfalls automatically
- [ ] Provides clear error messages with solutions
- [ ] Supports at least 3 Linux distributions
- [ ] Includes comprehensive tests
- [ ] Documentation is clear and user-friendly
- [ ] Can recover from common failures

## 🔗 Related Issues

- Installation guide: https://github.com/alijiujiu123/openclaw/commit/2e3982f68
- Docker setup guide: https://til.simonwillison.net/llms/openclaw-docker

## 📅 Tasks

1. Create skill structure
2. Implement environment detection
3. Implement prerequisite checker
4. Implement installer automation
5. Create configuration wizard
6. Implement systemd service manager
7. Create verification tests
8. Add troubleshooting knowledge base
9. Write documentation
10. Test on multiple platforms

## 💡 Future Enhancements

- Support for Docker deployment
- Unattended/automated install mode
- Configuration backup/restore
- Update management
- Multi-server deployment
- Cloud provider-specific optimizations (DigitalOcean, AWS, GCP)

---

**Label:** `enhancement` `skill` `automation` `good-first-issue`

**Assignees:** @openclaw/community

**Milestone:** v1.0
