#!/bin/bash
# OpenClaw Docker 数据恢复脚本
# 用于从备份恢复所有个人数据

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

# 打印函数
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_header() { echo -e "\n${BLUE}=============================================\n$1\n=============================================${NC}\n"; }

# 显示帮助
show_help() {
    cat << EOF
OpenClaw Docker 数据恢复脚本

用法:
  $ ./docker-restore.sh [备份名称]

参数:
  备份名称    要恢复的备份名称（时间戳，如: openclaw-backup-20260205_143000）
              如果不提供，将显示可用备份列表

示例:
  $ ./docker-restore.sh                              # 查看可用备份
  $ ./docker-restore.sh openclaw-backup-20260205_143000  # 恢复指定备份

注意:
  ⚠️  恢复操作会覆盖当前所有数据
  ⚠️  建议先备份当前数据: ./docker-backup.sh
  ⚠️  容器需要在恢复后重启

EOF
}

# 列出可用备份
list_backups() {
    print_header "可用备份列表"

    if [ ! -d "${BACKUP_DIR}" ] || [ -z "$(ls -A ${BACKUP_DIR} 2>/dev/null)" ]; then
        print_warning "没有找到备份"
        return 1
    fi

    # 查找所有备份的 manifest 文件
    find "${BACKUP_DIR}" -name "*-manifest.txt" -type f | sort -r | while read manifest; do
        backup_name=$(basename "${manifest}" "-manifest.txt")
        echo ""
        print_info "备份: ${backup_name}"
        grep -A 20 "备份时间:" "${manifest}" | head -21
    done

    echo ""
    print_info "使用方法: ./docker-restore.sh <备份名称>"
}

# 确认恢复操作
confirm_restore() {
    local backup_name=$1

    print_warning "⚠️  警告：恢复操作会覆盖当前所有数据！"
    echo ""
    echo "将恢复备份: ${backup_name}"
    echo ""
    read -p "确认恢复? (请输入 'yes' 继续): " confirmation

    if [ "$confirmation" != "yes" ]; then
        print_info "已取消恢复"
        exit 0
    fi
}

# 停止容器
stop_container() {
    print_info "停止容器..."

    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker compose -f docker-compose.dev.yml stop
        print_success "容器已停止"
    else
        print_info "容器未运行"
    fi
}

# 恢复数据卷
restore_volumes() {
    local backup_name=$1

    print_header "恢复数据卷"

    # 删除旧数据卷
    print_info "删除旧数据卷..."
    docker volume rm openclaw-dev-data openclaw-dev-skills 2>/dev/null || true

    # 创建新数据卷
    print_info "创建新数据卷..."
    docker volume create openclaw-dev-data
    docker volume create openclaw-dev-skills

    # 恢复核心数据
    if [ -f "${BACKUP_DIR}/${backup_name}-data.tar.gz" ]; then
        print_info "恢复核心数据..."
        docker run --rm \
            -v openclaw-dev-data:/data \
            -v "$(pwd)/${BACKUP_DIR}:/backup" \
            alpine:latest \
            sh -c "tar xzf /backup/${backup_name}-data.tar.gz -C /data"
        print_success "核心数据恢复完成"
    else
        print_error "找不到核心数据备份文件"
        return 1
    fi

    # 恢复技能数据
    if [ -f "${BACKUP_DIR}/${backup_name}-skills.tar.gz" ]; then
        print_info "恢复技能数据..."
        docker run --rm \
            -v openclaw-dev-skills:/skills \
            -v "$(pwd)/${BACKUP_DIR}:/backup" \
            alpine:latest \
            sh -c "tar xzf /backup/${backup_name}-skills.tar.gz -C /skills"
        print_success "技能数据恢复完成"
    else
        print_info "未找到技能数据备份，跳过"
    fi
}

# 恢复配置文件
restore_config_files() {
    local backup_name=$1

    print_header "恢复配置文件"

    # 恢复 .env 文件
    if [ -f "${BACKUP_DIR}/${backup_name}-env.txt" ]; then
        print_info "恢复 .env 文件..."
        if [ -f .env ]; then
            cp .env ".env.backup-$(date +%Y%m%d_%H%M%S)"
            print_warning "已备份当前 .env 文件"
        fi
        cp "${BACKUP_DIR}/${backup_name}-env.txt" .env
        print_success ".env 文件已恢复"
    fi

    # 恢复 workspace
    if [ -f "${BACKUP_DIR}/${backup_name}-workspace.tar.gz" ]; then
        print_info "恢复 workspace..."
        if [ -d workspace ]; then
            mv workspace "workspace.backup-$(date +%Y%m%d_%H%M%S)"
            print_warning "已备份当前 workspace"
        fi
        tar xzf "${BACKUP_DIR}/${backup_name}-workspace.tar.gz"
        print_success "workspace 已恢复"
    fi
}

# 启动容器
start_container() {
    print_info "启动容器..."
    docker compose -f docker-compose.dev.yml start
    print_success "容器已启动"
}

# 验证恢复
verify_restore() {
    print_header "验证恢复"

    # 等待容器启动
    sleep 3

    # 检查容器状态
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_success "容器运行正常"

        # 检查数据卷
        if docker volume ls | grep -q "openclaw-dev-data"; then
            print_success "数据卷已恢复"
        fi

        echo ""
        print_info "建议执行以下命令验证数据："
        echo "  ./docker-dev.sh shell"
        echo "  openclaw status"
        echo "  openclaw agents list"
    else
        print_warning "容器未运行，请手动启动: ./docker-dev.sh start"
    fi
}

# 主函数
main() {
    local backup_name=$1

    print_header "OpenClaw Docker 数据恢复"

    # 如果没有提供备份名称，显示可用备份列表
    if [ -z "$backup_name" ]; then
        list_backups
        exit 0
    fi

    # 验证备份是否存在
    if [ ! -f "${BACKUP_DIR}/${backup_name}-data.tar.gz" ]; then
        print_error "找不到备份: ${backup_name}"
        echo ""
        list_backups
        exit 1
    fi

    # 确认恢复
    confirm_restore "$backup_name"

    # 执行恢复
    stop_container
    restore_volumes "$backup_name"
    restore_config_files "$backup_name"
    start_container
    verify_restore

    print_header "恢复完成"
    print_success "所有数据已成功恢复！"
}

# 处理帮助参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 运行主函数
main "$@"
