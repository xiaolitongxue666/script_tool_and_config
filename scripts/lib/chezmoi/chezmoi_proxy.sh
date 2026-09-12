#!/usr/bin/env bash

# chezmoi 代理检测与设置（由 chezmoi_core.sh source）

# ============================================

# 代理是否被显式禁用（PROXY=none/false 或 NO_PROXY=1）
chezmoi_proxy_disabled() {
    if [[ "${NO_PROXY:-0}" == "1" ]]; then
        return 0
    fi
    local proxy="${PROXY:-${http_proxy:-}}"
    case "$proxy" in
        none|false|NONE|FALSE) return 0 ;;
    esac
    return 1
}

# 代理检测日志（stderr，避免污染 stdout 返回值）
_chezmoi_log_proxy_detect() {
    echo "[INFO] $*" >&2
}

# headless Linux 代理端口探测（与 agent-config PROXY_PROBE_PORTS 对齐）
chezmoi_proxy_port_is_listening() {
    local host="$1"
    local port="$2"
    if command -v ss &>/dev/null; then
        ss -tlnH 2>/dev/null | grep -qE "(^|:)${host}:${port}([[:space:]]|$)" && return 0
        ss -tlnH 2>/dev/null | grep -qE ":${port}([[:space:]]|$)" && return 0
        return 1
    fi
    if command -v netstat &>/dev/null; then
        netstat -tln 2>/dev/null | grep -qE ":${port}[[:space:]]" && return 0
    fi
    return 1
}

chezmoi_proxy_verify_url() {
    local url="$1"
    [[ "${PROXY_DISCOVER_VERIFY:-1}" == "1" ]] || return 0
    command -v curl &>/dev/null || return 0
    local code
    code="$(curl --noproxy '*' -x "$url" -s -o /dev/null -w '%{http_code}' --connect-timeout 2 https://api.github.com 2>/dev/null || echo "000")"
    [[ "$code" != "000" && -n "$code" ]]
}

# stdout: 在指定 host 上按 PROXY_PROBE_PORTS 顺序探测到的 proxy URL；失败时 stdout 为空
chezmoi_discover_proxy_url_on_host() {
    local host="${1:-127.0.0.1}"
    [[ "${PROXY_AUTO_DISCOVER:-true}" != "false" ]] || return 1
    local ports="${PROXY_PROBE_PORTS:-7890 17890 7897 10808 1080}"
    local port url
    for port in $ports; do
        if ! chezmoi_proxy_port_is_listening "$host" "$port"; then
            continue
        fi
        url="http://${host}:${port}"
        if chezmoi_proxy_verify_url "$url"; then
            echo "$url"
            return 0
        fi
    done
    return 1
}

# stdout: 探测到的 proxy URL；失败时 stdout 为空（默认 127.0.0.1）
chezmoi_discover_headless_proxy_url() {
    chezmoi_discover_proxy_url_on_host "127.0.0.1"
}

# 根据平台自动检测代理
# stdout 仅输出 URL；日志写 stderr
#  - 环境变量 PROXY / http_proxy（none/false 视为禁用，输出空）
#  - WSL 下从 resolv.conf 获取宿主机 IP:7890
#  - headless 原生 Linux：扫描 PROXY_PROBE_PORTS（VPS mihomo 常用 17890）
#  - 否则 127.0.0.1:7890
chezmoi_detect_proxy() {
    if chezmoi_proxy_disabled; then
        _chezmoi_log_proxy_detect "Proxy disabled (PROXY=${PROXY:-unset}, http_proxy=${http_proxy:-unset}, NO_PROXY=${NO_PROXY:-0})"
        return 0
    fi

    local proxy="${PROXY:-${http_proxy:-}}"
    local os
    os="$(uname -s 2>/dev/null || echo unknown)"

    if [[ -n "$proxy" ]]; then
        _chezmoi_log_proxy_detect "Proxy source: env (OS=${os}, WSL=$(chezmoi_is_wsl && echo yes || echo no))"
        echo "$proxy"
        return 0
    fi

    if chezmoi_is_wsl; then
        local host_ip discovered
        host_ip=$(awk '/^nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null)
        if [[ -n "$host_ip" ]]; then
            # WSL：在宿主机(nameserver)上按 PROXY_PROBE_PORTS 顺序探测（7890 优先，兼容 17890）
            discovered="$(chezmoi_discover_proxy_url_on_host "$host_ip" 2>/dev/null || true)"
            if [[ -n "$discovered" ]]; then
                _chezmoi_log_proxy_detect "Proxy source: wsl_host_probe (nameserver=${host_ip}, url=${discovered}, OS=${os})"
                echo "$discovered"
                return 0
            fi
            _chezmoi_log_proxy_detect "Proxy source: wsl_host (nameserver=${host_ip}, OS=${os})"
            echo "http://${host_ip}:7890"
            return 0
        fi
        _chezmoi_log_proxy_detect "Proxy source: wsl_fallback (no nameserver in resolv.conf, using 127.0.0.1)"
    elif chezmoi_is_headless_native_linux; then
        local discovered
        discovered="$(chezmoi_discover_headless_proxy_url 2>/dev/null || true)"
        if [[ -n "$discovered" ]]; then
            _chezmoi_log_proxy_detect "Proxy source: headless_linux_discover (OS=${os}, url=${discovered})"
            echo "$discovered"
            return 0
        fi
        _chezmoi_log_proxy_detect "Proxy source: headless_linux_fallback (no listening probe port, using 127.0.0.1:7890)"
    else
        _chezmoi_log_proxy_detect "Proxy source: default_local (OS=${os}, WSL=no)"
    fi

    echo "http://127.0.0.1:7890"
}

# 清除所有代理相关环境变量
_chezmoi_unset_proxy_env() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY PROXY PROXY_HOST PROXY_PORT \
        GIT_HTTP_PROXY GIT_HTTPS_PROXY all_proxy ALL_PROXY 2>/dev/null || true
}

# 设置代理环境变量
# 参数: proxy_url (可选，默认 chezmoi_detect_proxy)
chezmoi_setup_proxy() {
    if chezmoi_proxy_disabled; then
        _chezmoi_unset_proxy_env
        echo "[INFO] No proxy set, using direct connection" >&2
        return 0
    fi

    local proxy_url="${1:-$(chezmoi_detect_proxy)}"

    if [[ -z "$proxy_url" ]]; then
        _chezmoi_unset_proxy_env
        echo "[INFO] No proxy set, using direct connection" >&2
        return 0
    fi

    if [[ ! "$proxy_url" =~ ^https?:// ]]; then
        proxy_url="http://${proxy_url}"
    fi

    export PROXY="$proxy_url"
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    export GIT_HTTP_PROXY="$proxy_url"
    export GIT_HTTPS_PROXY="$proxy_url"

    local stripped="${proxy_url#*://}"
    local host="${stripped%%:*}"
    local port="${stripped#*:}"
    port="${port%%/*}"
    [[ -z "$port" || "$port" = "$host" ]] && port="7890"
    export PROXY_HOST="$host"
    export PROXY_PORT="$port"

    echo "[INFO] Proxy set: $proxy_url" >&2
    echo "[INFO] Proxy host: $host, Proxy port: $port" >&2
}

# ============================================
# chezmoi 锁管理
