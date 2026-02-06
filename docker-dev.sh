#!/bin/bash
# OpenClaw Docker 开发环境快速启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_header() {
    echo -e "${BLUE}"
    echo "============================================="
    echo "$1"
    echo "============================================="
    echo -e "${NC}"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装，请先安装"
        exit 1
    fi
}

# 检查 Docker 和 Docker Compose
check_prerequisites() {
    print_header "检查前置条件"

    check_command "docker"
    check_command "docker compose"

    print_success "Docker 已安装: $(docker --version)"
    print_success "Docker Compose 已安装"
}

# 检查 .env 文件
check_env_file() {
    print_header "检查环境配置"

    if [ ! -f .env ]; then
        print_warning ".env 文件不存在"

        if [ -f .env.example ]; then
            print_info "从 .env.example 创建 .env 文件"
            cp .env.example .env
            print_success ".env 文件已创建"
            print_warning "请编辑 .env 文件，添加你的 API keys"
            print_info "vim .env"
            echo ""
            read -p "按 Enter 继续（确保已配置 .env 文件）..."
        else
            print_error ".env.example 文件不存在"
            exit 1
        fi
    else
        print_success ".env 文件已存在"
    fi
}

# 构建 Docker 镜像
build_image() {
    print_header "构建 Docker 镜像"

    print_info "这可能需要 5-10 分钟（首次构建）..."

    if docker compose -f docker-compose.dev.yml build; then
        print_success "镜像构建成功"
    else
        print_error "镜像构建失败"
        exit 1
    fi
}

# 启动容器
start_container() {
    print_header "启动开发容器"

    if docker compose -f docker-compose.dev.yml up -d; then
        print_success "容器启动成功"
        echo ""
        print_info "容器状态："
        docker compose -f docker-compose.dev.yml ps
    else
        print_error "容器启动失败"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    print_header "OpenClaw Docker 开发环境"
    cat << EOF

使用方法:
  $ ./docker-dev.sh [命令]

命令:
  start       启动开发环境（默认）
  stop        停止开发环境
  restart     重启开发环境
  build       构建 Docker 镜像
  rebuild     重新构建 Docker 镜像（无缓存）
  shell       进入容器 Shell
  logs        查看容器日志
  status      查看容器状态
  backup      备份所有数据（配置、记忆、工具等）
  restore     恢复备份数据
  clean       清理容器和镜像
  help        显示此帮助信息

数据管理:
  backup      备份所有个人数据到 ./backups 目录
  restore     从备份恢复数据（查看可用备份: ./docker-restore.sh）

示例:
  ./docker-dev.sh           # 首次使用：启动开发环境
  ./docker-dev.sh shell     # 进入容器进行开发
  ./docker-dev.sh logs      # 查看日志
  ./docker-dev.sh backup    # 备份所有数据
  ./docker-dev.sh stop      # 停止环境

更多信息:
  DOCKER_DEV.md         - Docker 开发环境完整指南
  DOCKER_PERSISTENCE.md - 数据持久化和备份恢复指南

EOF
}

# 进入容器 Shell
enter_shell() {
    print_info "进入容器 Shell..."
    docker compose -f docker-compose.dev.yml exec openclaw-dev sh
}

# 查看日志
show_logs() {
    print_info "查看容器日志（Ctrl+C 退出）..."
    docker compose -f docker-compose.dev.yml logs -f
}

# 查看状态
show_status() {
    print_header "容器状态"
    docker compose -f docker-compose.dev.yml ps
    echo ""
    print_info "容器健康状态："
    docker inspect --format='{{.State.Health.Status}}' openclaw-dev 2>/dev/null || echo "容器未运行"
}

# 停止容器
stop_container() {
    print_header "停止开发容器"
    docker compose -f docker-compose.dev.yml stop
    print_success "容器已停止"
}

# 重启容器
restart_container() {
    print_header "重启开发容器"
    docker compose -f docker-compose.dev.yml restart
    print_success "容器已重启"
    echo ""
    show_logs
}

# 清理环境
clean_environment() {
    print_header "清理开发环境"
    print_warning "这将删除容器和镜像（数据卷会保留）"
    print_info "建议先备份数据: ./docker-dev.sh backup"

    read -p "确认清理? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose -f docker-compose.dev.yml down
        docker rmi openclaw-dev:latest 2>/dev/null || true
        print_success "清理完成"
        print_info "数据卷已保留（如需删除数据卷，运行: docker volume rm openclaw-dev-data openclaw-dev-skills）"
    else
        print_info "已取消清理"
    fi
}

# 备份数据
backup_data() {
    if [ -f ./docker-backup.sh ]; then
        ./docker-backup.sh
    else
        print_error "找不到备份脚本 docker-backup.sh"
        exit 1
    fi
}

# 恢复数据
restore_data() {
    if [ -f ./docker-restore.sh ]; then
        ./docker-restore.sh "$@"
    else
        print_error "找不到恢复脚本 docker-restore.sh"
        exit 1
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            check_prerequisites
            check_env_file
            build_image
            start_container
            echo ""
            print_success "开发环境已就绪！"
            echo ""
            print_info "下一步："
            echo "  1. 进入容器: ./docker-dev.sh shell"
            echo "  2. 查看日志: ./docker-dev.sh logs"
            echo "  3. 查看状态: ./docker-dev.sh status"
            echo "  4. 备份数据: ./docker-dev.sh backup"
            echo ""
            print_info "在容器内常用命令："
            echo "  openclaw status        # 检查状态"
            echo "  pnpm test              # 运行测试"
            echo "  pnpm build             # 构建项目"
            echo "  pnpm gateway:dev       # 启动 Gateway"
            echo ""
            ;;
        stop)
            stop_container
            ;;
        restart)
            restart_container
            ;;
        build)
            check_prerequisites
            build_image
            ;;
        rebuild)
            check_prerequisites
            print_header "重新构建 Docker 镜像（无缓存）"
            docker compose -f docker-compose.dev.yml build --no-cache
            print_success "镜像重新构建完成"
            ;;
        shell)
            enter_shell
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        backup)
            backup_data
            ;;
        restore)
            shift
            restore_data "$@"
            ;;
        clean)
            clean_environment
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
