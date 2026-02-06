#!/bin/sh
set -e

echo "Starting OpenClaw Gateway in Docker..."
echo "Date: $(date)"
echo "Node version: $(node --version)"
echo "Working directory: $(pwd)"
echo "Environment:"
echo "  GATEWAY_MODE=${GATEWAY_MODE:-local}"
echo "  GATEWAY_BIND=${GATEWAY_BIND:-0.0.0.0}"
echo "  GATEWAY_PORT=${GATEWAY_PORT:-18789}"
echo ""

# 启动 Gateway（从环境变量读取配置）
cd /app
exec node dist/index.js gateway run
