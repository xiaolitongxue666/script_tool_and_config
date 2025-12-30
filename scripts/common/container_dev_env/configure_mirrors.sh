#!/bin/bash
# 配置镜像源脚本（用于 Dockerfile）

PROXY="${PROXY:-}"

if [ -z "$PROXY" ]; then
    echo "配置中国镜像源..."
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

    cat > /etc/pacman.d/mirrorlist <<'EOF'
## Aliyun (HTTPS, primary)
Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch
## USTC (HTTPS, secondary)
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
## Tencent Cloud (HTTPS, tertiary)
Server = https://mirrors.cloud.tencent.com/archlinux/$repo/os/$arch
## Huawei Cloud (HTTPS)
Server = https://mirrors.huaweicloud.com/repository/archlinux/$repo/os/$arch
## Nanjing University (HTTPS)
Server = https://mirrors.nju.edu.cn/archlinux/$repo/os/$arch
## Chongqing University (HTTPS)
Server = https://mirrors.cqu.edu.cn/archlinux/$repo/os/$arch
## Neusoft (HTTPS)
Server = https://mirrors.neusoft.edu.cn/archlinux/$repo/os/$arch
## Lanzhou University (HTTPS)
Server = https://mirror.lzu.edu.cn/archlinux/$repo/os/$arch
## Southern University of Science and Technology (HTTPS)
Server = https://mirrors.sustech.edu.cn/archlinux/$repo/os/$arch
EOF

    # 优化 pacman 配置
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf || true
    if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
        sed -i '/^\[options\]/a\ParallelDownloads = 5' /etc/pacman.conf
    fi

    # 添加 archlinuxcn 源
    if ! grep -q "archlinuxcn" /etc/pacman.conf; then
        cat >> /etc/pacman.conf <<'EOF'
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
Server = https://mirrors.aliyun.com/archlinuxcn/$arch
Server = https://mirrors.cloud.tencent.com/archlinuxcn/$arch
Server = https://mirrors.huaweicloud.com/repository/archlinuxcn/$arch
Server = https://mirrors.nju.edu.cn/archlinuxcn/$arch
Server = https://mirrors.cqu.edu.cn/archlinuxcn/$arch
Server = https://mirror.lzu.edu.cn/archlinuxcn/$arch
Server = https://mirrors.sustech.edu.cn/archlinuxcn/$arch
EOF
    fi
    # 移除任何 XferCommand（使用默认下载器）
    sed -i '/^XferCommand/d' /etc/pacman.conf
else
    echo "使用代理，不修改镜像源"
    # 确保 pacman 目录存在
    mkdir -p /var/lib/pacman/sync /var/cache/pacman/pkg
    chmod 777 /var/lib/pacman/sync /var/cache/pacman/pkg
    # 配置 pacman 使用代理
    # 移除任何现有的 XferCommand
    sed -i '/^XferCommand/d' /etc/pacman.conf
    # 创建包装脚本，从环境变量读取代理
    mkdir -p /usr/local/bin
    cat > /usr/local/bin/pacman-curl-proxy.sh <<'SCRIPTEOF'
#!/bin/bash
# pacman curl wrapper with proxy support
# pacman passes: %u (URL) as $1, %o (output file) as $2
URL="$1"
OUTPUT="$2"
OUTPUT_DIR="$(dirname "$OUTPUT")"
# 确保输出目录存在且有写权限
mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
chmod 777 "$OUTPUT_DIR" 2>/dev/null || true
# 使用 /tmp 作为临时下载目录
TEMP_FILE="/tmp/$(basename "$OUTPUT").$$"
# 从环境变量读取代理
PROXY="${http_proxy:-${HTTP_PROXY:-${https_proxy:-${HTTPS_PROXY:-}}}}"
# 重试机制：最多重试 3 次
MAX_RETRIES=3
RETRY_COUNT=0
EXIT_CODE=1

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # 使用 curl 下载到临时文件，添加超时和重试参数
    if [ -n "$PROXY" ]; then
        /usr/bin/curl --connect-timeout 30 --max-time 300 --retry 2 --retry-delay 1 \
            -C - -f --proxy "$PROXY" -L -o "$TEMP_FILE" "$URL" 2>/dev/null
    else
        /usr/bin/curl --connect-timeout 30 --max-time 300 --retry 2 --retry-delay 1 \
            -C - -f -L -o "$TEMP_FILE" "$URL" 2>/dev/null
    fi
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ] && [ -f "$TEMP_FILE" ] && [ -s "$TEMP_FILE" ]; then
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        sleep 2
        rm -f "$TEMP_FILE" 2>/dev/null || true
    fi
done

if [ $EXIT_CODE -eq 0 ] && [ -f "$TEMP_FILE" ] && [ -s "$TEMP_FILE" ]; then
    # 先删除目标文件（如果存在）
    rm -f "$OUTPUT" 2>/dev/null || true
    # 确保目录权限
    chmod 777 "$OUTPUT_DIR" 2>/dev/null || true
    # 复制到目标位置
    cp "$TEMP_FILE" "$OUTPUT" && chmod 666 "$OUTPUT" 2>/dev/null || true
    rm -f "$TEMP_FILE" 2>/dev/null || true
    exit 0
else
    rm -f "$TEMP_FILE" 2>/dev/null || true
    exit $EXIT_CODE
fi
SCRIPTEOF
    chmod +x /usr/local/bin/pacman-curl-proxy.sh
    # 配置 XferCommand
    sed -i '/^\[options\]/a\XferCommand = /usr/local/bin/pacman-curl-proxy.sh %u %o' /etc/pacman.conf
fi
