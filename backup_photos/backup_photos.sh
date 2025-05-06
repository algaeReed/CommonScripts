#!/bin/bash

# ==============================================
# 手机照片备份工具
# 功能: 从安卓设备备份照片到本地计算机
# ==============================================

# 初始化默认值
DEFAULT_LOCAL_DIR="./phone_photos"
DEFAULT_LOG_FILE="photo_backup.log"
INCLUDE_HIDDEN=false

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo -e "${GREEN}用法: $0 [选项]${NC}"
    echo -e "选项:"
    echo -e "  ${BLUE}--output=DIR${NC}      指定本地保存目录 (默认: ${DEFAULT_LOCAL_DIR})"
    echo -e "  ${BLUE}--whitelist=DIR1,DIR2${NC} 添加白名单目录"
    echo -e "  ${BLUE}--blacklist=DIR1,DIR2${NC} 添加黑名单目录"
    echo -e "  ${BLUE}--start-date=YYYY-MM-DD${NC} 只下载此日期之后的照片"
    echo -e "  ${BLUE}--end-date=YYYY-MM-DD${NC}   只下载此日期之前的照片"
    echo -e "  ${BLUE}--log=FILE${NC}       指定日志文件 (默认: ${DEFAULT_LOG_FILE})"
    echo -e "  ${BLUE}--include-hidden${NC}  包含隐藏文件夹(以.开头)"
    echo -e "  ${BLUE}--help${NC}           显示帮助信息"
    exit 0
}

# 日志记录函数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local color=""
    
    case "$level" in
        "INFO") color="${BLUE}" ;;
        "SUCCESS") color="${GREEN}" ;;
        "WARNING") color="${YELLOW}" ;;
        "ERROR") color="${RED}" ;;
        *) color="${NC}" ;;
    esac
    
    echo -e "${color}[${timestamp}] [${level}] ${message}${NC}" | tee -a "$LOG_FILE"
}

# 检查ADB是否可用
check_adb() {
    if ! command -v adb &> /dev/null; then
        log "ERROR" "adb未安装，请先安装Android SDK Platform-Tools"
        exit 1
    fi

    if ! adb devices | grep -q "device$"; then
        log "ERROR" "没有找到已连接的安卓设备，请检查:"
        log "ERROR" "1. USB调试是否已启用"
        log "ERROR" "2. 设备是否已授权"
        log "ERROR" "3. 使用 'adb devices' 确认设备列表"
        exit 1
    fi
}

# 主备份函数
backup_photos() {
    local total_files=0
    local success_count=0
    local fail_count=0
    local skip_count=0
    local hidden_skip_count=0

    # 构建日期筛选参数
    local date_filter=""
    if [[ -n "$START_DATE" ]]; then
        date_filter+=" -newermt \"$START_DATE\""
    fi
    if [[ -n "$END_DATE" ]]; then
        date_filter+=" ! -newermt \"$END_DATE 23:59:59\""
    fi

    # 构建黑名单排除参数
    local blacklist_args=""
    for dir in "${BLACK_LIST[@]}"; do
        blacklist_args+=" -not -path \"$dir/*\""
    done

    # 如果不包含隐藏文件夹，添加排除参数
    if [[ "$INCLUDE_HIDDEN" != "true" ]]; then
        blacklist_args+=" -not -path '*/.*'"
    fi

    log "INFO" "开始照片备份过程..."
    log "INFO" "扫描范围: /sdcard"
    log "INFO" "包含的图片格式: ${PHOTO_EXTS[@]}"
    [[ -n "$START_DATE" ]] && log "INFO" "开始日期: $START_DATE"
    [[ -n "$END_DATE" ]] && log "INFO" "结束日期: $END_DATE"

    # 遍历所有照片目录
    for dir in "${unique_dirs[@]}"; do
        # 跳过空目录
        [ -z "$dir" ] && continue
        
        log "INFO" "正在扫描目录: $dir"
        
        # 获取目录中的照片文件列表
        local find_cmd="find \"$dir\" -type f $ext_args $blacklist_args $date_filter 2>/dev/null"
        local files
        files=$(adb shell "$find_cmd" | tr -d '\r')
        
        # 统计文件数量
        local dir_file_count=$(echo "$files" | wc -w)
        ((total_files += dir_file_count))
        
        # 如果没有文件，跳过该目录
        if [[ $dir_file_count -eq 0 ]]; then
            log "INFO" "目录中没有符合条件的文件，跳过"
            continue
        fi

        log "INFO" "找到 $dir_file_count 个文件需要处理"
        
        # 处理每个文件
        local current=0
        while IFS= read -r file; do
            [ -z "$file" ] && continue
            ((current++))
            
            # 检查是否隐藏文件(即使包含隐藏文件夹，也单独检查隐藏文件)
            if [[ "$INCLUDE_HIDDEN" != "true" ]] && [[ "$(basename "$file")" == .* ]]; then
                log "INFO" "[$current/$dir_file_count] 跳过隐藏文件: $file"
                ((hidden_skip_count++))
                continue
            fi
            
            # 创建本地子目录结构
            local relative_path=${file#/sdcard/}
            relative_path=$(dirname "$relative_path")
            local local_subdir="$LOCAL_DIR/$relative_path"
            mkdir -p "$local_subdir"
            
            # 检查文件是否已存在
            local local_file="$local_subdir/$(basename "$file")"
            if [[ -f "$local_file" ]]; then
                log "INFO" "[$current/$dir_file_count] 跳过已存在文件: $file"
                ((skip_count++))
                continue
            fi
            
            # 下载文件
            log "INFO" "[$current/$dir_file_count] 正在下载: $file"
            if adb pull "$file" "$local_subdir/" &> /dev/null; then
                log "SUCCESS" "下载成功: $file"
                ((success_count++))
            else
                log "ERROR" "下载失败: $file"
                ((fail_count++))
            fi
            
        done <<< "$files"
    done

    # 输出统计信息
    log "INFO" "备份完成，统计信息:"
    log "INFO" "扫描的总目录数: ${#unique_dirs[@]}"
    log "INFO" "发现的总文件数: $total_files"
    log "INFO" "成功下载文件: $success_count"
    log "INFO" "跳过隐藏文件/目录: $hidden_skip_count"
    log "INFO" "跳过已存在文件: $skip_count"
    log "INFO" "下载失败文件: $fail_count"
    
    if [[ $fail_count -gt 0 ]]; then
        log "WARNING" "有 $fail_count 个文件下载失败，请检查日志获取详细信息"
    fi
}

# 主程序
main() {
    # 设置默认值
    LOCAL_DIR="$DEFAULT_LOCAL_DIR"
    LOG_FILE="$DEFAULT_LOG_FILE"
    WHITE_LIST=(
        "/sdcard/DCIM"
        "/sdcard/Pictures"
        "/sdcard/WhatsApp/Media"
    )
    BLACK_LIST=(
        "/sdcard/Android"
        "/sdcard/.thumbnails"
        "/sdcard/.trash"
    )
    PHOTO_EXTS=("jpg" "jpeg" "png" "gif" "bmp" "webp" "heic")

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output=*)
                LOCAL_DIR="${1#*=}"
                shift
                ;;
            --whitelist=*)
                IFS=',' read -ra ADD_WHITE <<< "${1#*=}"
                WHITE_LIST+=("${ADD_WHITE[@]}")
                shift
                ;;
            --blacklist=*)
                IFS=',' read -ra ADD_BLACK <<< "${1#*=}"
                BLACK_LIST+=("${ADD_BLACK[@]}")
                shift
                ;;
            --start-date=*)
                START_DATE="${1#*=}"
                shift
                ;;
            --end-date=*)
                END_DATE="${1#*=}"
                shift
                ;;
            --log=*)
                LOG_FILE="${1#*=}"
                shift
                ;;
            --include-hidden)
                INCLUDE_HIDDEN=true
                shift
                ;;
            --help)
                show_help
                ;;
            *)
                log "ERROR" "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 初始化
    mkdir -p "$LOCAL_DIR"
    echo -e "照片备份日志 - $(date)\n" > "$LOG_FILE"
    check_adb

    # 构建find命令的扩展名参数
    ext_args=""
    for ext in "${PHOTO_EXTS[@]}"; do
        ext_args+=" -iname \"*.$ext\" -o"
    done
    ext_args="${ext_args% -o}"

    log "INFO" "正在搜索手机上的照片目录..."

    # 查找实际有照片的目录
    local find_cmd="find /sdcard -type f $ext_args 2>/dev/null | xargs -I {} dirname {} | sort -u"
    photo_dirs=$(adb shell "$find_cmd" | tr -d '\r')

    # 合并白名单目录
    all_dirs=("${WHITE_LIST[@]}")
    while IFS= read -r dir; do
        # 检查目录是否已经在白名单中
        found=0
        for wdir in "${WHITE_LIST[@]}"; do
            if [[ "$dir" == "$wdir"* ]]; then
                found=1
                break
            fi
        done
        
        # 如果不在白名单中，则添加
        if [[ $found -eq 0 ]]; then
            all_dirs+=("$dir")
        fi
    done <<< "$photo_dirs"

    # 去重
    IFS=$'\n' unique_dirs=($(printf "%s\n" "${all_dirs[@]}" | sort -u))
    unset IFS

    if [[ ${#unique_dirs[@]} -eq 0 ]]; then
        log "ERROR" "未找到任何照片目录"
        exit 1
    fi

    log "INFO" "将处理以下目录:"
    printf "  %s\n" "${unique_dirs[@]}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    # 执行备份
    backup_photos

    log "SUCCESS" "照片备份完成!"
    log "INFO" "本地目录: $LOCAL_DIR"
    log "INFO" "日志文件: $LOG_FILE"
}

# 启动主程序
main "$@"