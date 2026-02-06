#!/bin/bash
# OpenClaw Docker 数据备份脚本
# 用于备份所有个人数据（配置、记忆、工具、会话等）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
BACKUP_DIR="./backups"
CONTAINER_NAME="openclaw-dev"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="openclaw-backup-${TIMESTAMP}"
TEMP_DIR="/tmp/backup-${TIMESTAMP}"

# 打印函数
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_header() { echo -e "\n${BLUE}=============================================\n$1\n=============================================${NC}\n"; }

# 检查容器是否运行
check_container() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_error "容器 ${CONTAINER_NAME} 未运行"
        print_info "请先启动容器: ./docker-dev.sh start"
        exit 1
    fi
}

# 创建备份目录
create_backup_dir() {
    mkdir -p "${BACKUP_DIR}"
    print_success "备份目录: ${BACKUP_DIR}"
}

# 备份数据卷
backup_volumes() {
    print_header "开始备份数据卷"

    # 创建临时容器用于备份数据
    print_info "正在备份核心数据..."

    docker run --rm \
        -v openclaw-dev-data:/data \
        -v openclaw-dev-skills:/skills \
        -v "$(pwd)/${BACKUP_DIR}:/backup" \
        alpine:latest \
        sh -c "
            cd /data &&
            tar czf /backup/${BACKUP_NAME}-data.tar.gz . &&
            echo '✓ 核心数据备份完成'
        "

    # 备份技能数据（如果存在）
    print_info "正在备份技能数据..."
    docker run --rm \
        -v openclaw-dev-skills:/skills \
        -v "$(pwd)/${BACKUP_DIR}:/backup" \
        alpine:latest \
        sh -c "
            if [ -d /skills ] && [ \"\$(ls -A /skills 2>/dev/null)\" ]; then
                tar czf /backup/${BACKUP_NAME}-skills.tar.gz . -C /skills .
                echo '✓ 技能数据备份完成'
            else
                echo '! 技能目录为空，跳过'
            fi
        "

    print_success "数据卷备份完成"
}

# 备份配置文件
backup_config_files() {
    print_header "备份配置文件"

    # 备份 .env 文件（如果存在）
    if [ -f .env ]; then
        cp .env "${BACKUP_DIR}/${BACKUP_NAME}-env.txt"
        print_success ".env 文件已备份"
    else
        print_warning ".env 文件不存在，跳过"
    fi

    # 备份 workspace（如果存在且有内容）
    if [ -d workspace ] && [ -n "$(ls -A workspace 2>/dev/null)" ]; then
        tar czf "${BACKUP_DIR}/${BACKUP_NAME}-workspace.tar.gz" workspace
        print_success "workspace 已备份"
    else
        print_info "workspace 为空，跳过"
    fi
}

# 创建备份清单
create_manifest() {
    print_header "创建备份清单"

    cat > "${BACKUP_DIR}/${BACKUP_NAME}-manifest.txt" << EOF
OpenClaw Docker 数据备份清单
============================

备份时间: $(date)
备份名称: ${BACKUP_NAME}
容器名称: ${CONTAINER_NAME}

备份文件列表:
$(ls -lh "${BACKUP_DIR}/${BACKUP_NAME}-"* 2>/dev/null | awk '{print "- " $9 " (" $5 ")"}')

数据卷信息:
- openclaw-dev-data: 核心配置、记忆、会话
- openclaw-dev-skills: 自定义技能、工具

恢复方法:
1. 运行: ./docker-restore.sh ${BACKUP_NAME}
2. 或手动: docker volume rm openclaw-dev-data openclaw-dev-skills
           docker run --rm -v openclaw-dev-data:/data -v \$(pwd)/${BACKUP_DIR}:/backup alpine sh -c "tar xzf /backup/${BACKUP_NAME}-data.tar.gz -C /data"
EOF

    print_success "备份清单已创建"
}

# 显示备份结果
show_summary() {
    print_header "备份完成"

    echo "备份位置: ${BACKUP_DIR}"
    echo ""
    echo "备份文件:"
    ls -lh "${BACKUP_DIR}/${BACKUP_NAME}-"* 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
    print_success "备份成功！共备份以下数据："
    echo "  ✓ 核心配置 (openclaw.json, channels, credentials)"
    echo "  ✓ Agent 记忆和会话"
    echo "  ✓ 自定义技能和工具"
    echo "  ✓ 工作空间文件"
    echo "  ✓ 环境变量配置"
    echo ""
    print_info "恢复命令: ./docker-restore.sh ${BACKUP_NAME}"
}

# 主函数
main() {
    print_header "OpenClaw Docker 数据备份"

    check_container
    create_backup_dir
    backup_volumes
    backup_config_files
    create_manifest
    show_summary
}

# 运行
main "$@"
