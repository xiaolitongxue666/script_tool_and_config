#!/usr/bin/env bash

# 镜像源可用性测试脚本
# 测试中国大陆 Arch Linux 镜像源的可用性

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试函数
test_mirror() {
    local mirror_name="$1"
    local mirror_url="$2"
    local repo_type="$3"  # main 或 archlinuxcn

    echo -n "测试 ${mirror_name} (${repo_type})... "

    if [[ "${repo_type}" == "main" ]]; then
        local test_url="${mirror_url}/core/os/x86_64/core.db"
    else
        local test_url="${mirror_url}/x86_64/archlinuxcn.db"
    fi

    # 使用 curl 测试，设置超时
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "${test_url}" 2>/dev/null || echo "000")

    if [[ "${http_code}" == "200" ]]; then
        echo -e "${GREEN}✓ 可用 (HTTP ${http_code})${NC}"
        return 0
    elif [[ "${http_code}" == "403" ]]; then
        echo -e "${RED}✗ 禁止访问 (HTTP ${http_code})${NC}"
        return 1
    elif [[ "${http_code}" == "404" ]]; then
        echo -e "${RED}✗ 未找到 (HTTP ${http_code})${NC}"
        return 1
    else
        echo -e "${YELLOW}✗ 不可用 (HTTP ${http_code})${NC}"
        return 1
    fi
}

# 主仓库镜像列表
declare -a MAIN_MIRRORS=(
    "阿里云|https://mirrors.aliyun.com/archlinux"
    "中科大USTC|https://mirrors.ustc.edu.cn/archlinux"
    "清华大学TUNA|https://mirrors.tuna.tsinghua.edu.cn/archlinux"
    "163|http://mirrors.163.com/archlinux"
    "腾讯云|https://mirrors.cloud.tencent.com/archlinux"
    "华为云|https://mirrors.huaweicloud.com/repository/archlinux"
    "上海交大|https://mirror.sjtu.edu.cn/archlinux"
    "北京理工大学|https://mirror.bit.edu.cn/archlinux"
    "南京大学|https://mirrors.nju.edu.cn/archlinux"
    "重庆大学|https://mirrors.cqu.edu.cn/archlinux"
    "大连东软|https://mirrors.neusoft.edu.cn/archlinux"
    "兰州大学|https://mirror.lzu.edu.cn/archlinux"
    "北京外国语大学|https://mirrors.bfsu.edu.cn/archlinux"
    "南方科技大学|https://mirrors.sustech.edu.cn/archlinux"
)

# archlinuxcn 仓库镜像列表
declare -a ARCHLINUXCN_MIRRORS=(
    "中科大USTC|https://mirrors.ustc.edu.cn/archlinuxcn"
    "阿里云|https://mirrors.aliyun.com/archlinuxcn"
    "腾讯云|https://mirrors.cloud.tencent.com/archlinuxcn"
    "163|https://mirrors.163.com/archlinuxcn"
    "华为云|https://mirrors.huaweicloud.com/repository/archlinuxcn"
    "上海交大|https://mirror.sjtu.edu.cn/archlinuxcn"
    "北京理工大学|https://mirror.bit.edu.cn/archlinuxcn"
    "南京大学|https://mirrors.nju.edu.cn/archlinuxcn"
    "重庆大学|https://mirrors.cqu.edu.cn/archlinuxcn"
    "大连东软|https://mirrors.neusoft.edu.cn/archlinuxcn"
    "兰州大学|https://mirror.lzu.edu.cn/archlinuxcn"
    "北京外国语大学|https://mirrors.bfsu.edu.cn/archlinuxcn"
    "南方科技大学|https://mirrors.sustech.edu.cn/archlinuxcn"
)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Arch Linux 镜像源可用性测试${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 测试主仓库镜像
echo -e "${YELLOW}测试主仓库镜像 (core, extra, community)...${NC}"
echo ""

declare -a AVAILABLE_MAIN=()
for mirror_info in "${MAIN_MIRRORS[@]}"; do
    IFS='|' read -r name url <<< "${mirror_info}"
    if test_mirror "${name}" "${url}" "main"; then
        AVAILABLE_MAIN+=("${mirror_info}")
    fi
done

echo ""
echo -e "${YELLOW}测试 archlinuxcn 仓库镜像...${NC}"
echo ""

declare -a AVAILABLE_ARCHLINUXCN=()
for mirror_info in "${ARCHLINUXCN_MIRRORS[@]}"; do
    IFS='|' read -r name url <<< "${mirror_info}"
    if test_mirror "${name}" "${url}" "archlinuxcn"; then
        AVAILABLE_ARCHLINUXCN+=("${mirror_info}")
    fi
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}测试结果汇总${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 显示可用的主仓库镜像
echo -e "${GREEN}可用的主仓库镜像 (${#AVAILABLE_MAIN[@]} 个):${NC}"
if [[ ${#AVAILABLE_MAIN[@]} -eq 0 ]]; then
    echo -e "${RED}  无可用镜像${NC}"
else
    for i in "${!AVAILABLE_MAIN[@]}"; do
        IFS='|' read -r name url <<< "${AVAILABLE_MAIN[$i]}"
        echo "  $((i+1)). ${name}"
        echo "     ${url}"
    done
fi

echo ""

# 显示可用的 archlinuxcn 镜像
echo -e "${GREEN}可用的 archlinuxcn 镜像 (${#AVAILABLE_ARCHLINUXCN[@]} 个):${NC}"
if [[ ${#AVAILABLE_ARCHLINUXCN[@]} -eq 0 ]]; then
    echo -e "${RED}  无可用镜像${NC}"
else
    for i in "${!AVAILABLE_ARCHLINUXCN[@]}"; do
        IFS='|' read -r name url <<< "${AVAILABLE_ARCHLINUXCN[$i]}"
        echo "  $((i+1)). ${name}"
        echo "     ${url}"
    done
fi

echo ""

# 生成配置建议
if [[ ${#AVAILABLE_MAIN[@]} -gt 0 ]] || [[ ${#AVAILABLE_ARCHLINUXCN[@]} -gt 0 ]]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}配置建议${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    if [[ ${#AVAILABLE_MAIN[@]} -gt 0 ]]; then
        echo -e "${GREEN}主仓库镜像配置 (mirrorlist):${NC}"
        echo ""
        echo "# 按可用性排序的镜像源"
        for mirror_info in "${AVAILABLE_MAIN[@]}"; do
            IFS='|' read -r name url <<< "${mirror_info}"
            echo "Server = ${url}/\$repo/os/\$arch"
        done
        echo ""
    fi

    if [[ ${#AVAILABLE_ARCHLINUXCN[@]} -gt 0 ]]; then
        echo -e "${GREEN}archlinuxcn 仓库配置 (pacman.conf):${NC}"
        echo ""
        echo "[archlinuxcn]"
        echo "SigLevel = Optional TrustAll"
        for mirror_info in "${AVAILABLE_ARCHLINUXCN[@]}"; do
            IFS='|' read -r name url <<< "${mirror_info}"
            echo "Server = ${url}/\$arch"
        done
        echo ""
    fi
fi

echo ""
echo -e "${BLUE}测试完成${NC}"

