#!/usr/bin/env bash
# ============================================
# GitHub 钥匙与登录钥匙不串用；设备别名和用户与 Tailscale 角色一致
# 本测试只读模板，不碰 ~/.ssh，也不调用 tailscale
# 实机验收另做，不放进本脚本：
#   chezmoi apply -v --force ~/.ssh/config
#   ssh -o BatchMode=yes -T git@github.com
#   ssh -o BatchMode=yes <MagicDNS> whoami
# 手机和平板的客户端不是这份全量模板，只保留三台管理机
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE="${PROJECT_ROOT}/.chezmoi/dot_ssh/config.tmpl"

PASSED=0
FAILED=0

pass() { PASSED=$((PASSED + 1)); echo "[PASS] $1"; }
fail() { FAILED=$((FAILED + 1)); echo "[FAIL] $1"; }

echo "=========================================="
echo "SSH GitHub identity tests - $(date)"
echo "=========================================="

if [[ ! -f "$TEMPLATE" ]]; then
    echo "[FAIL] missing template: $TEMPLATE"
    exit 1
fi

github_block="$(awk '
    /^Host github.com$/ { capture=1 }
    capture && /^# --- VPS/ { exit }
    capture { print }
' "$TEMPLATE")"

login_keys_block="$(awk '
    /^# --- VPS/ { capture=1 }
    capture && /^# --- 生产域名/ { exit }
    capture { print }
' "$TEMPLATE")"

login_block="$login_keys_block"

moicen_block="$(awk '
    /^Host moicen.com$/ { capture=1 }
    capture && /^# 其他 Host/ { exit }
    capture { print }
' "$TEMPLATE")"

if [[ -n "$github_block" ]]; then
    pass "github.com host block exists"
else
    fail "github.com host block exists"
fi

if [[ -n "$login_block" ]]; then
    pass "device login block exists"
else
    fail "device login block exists"
fi

github_keys=(
    id_ed25519_mac-mini-2026-10-5s
    id_ed25519_desktop-win-2026-10-C4
    id_ed25519_vps-2026-10-JM
    id_ed25519_laptop-huawei-2026-10-5A
)
login_keys=(
    id_ed25519_mac-mini-2026-10-GY
    id_ed25519_desktop-win-2026-10-A8
    id_ed25519_laptop-huawei-2026-10-o4
)

for key_name in "${github_keys[@]}"; do
    if printf '%s\n' "$github_block" | grep -q "$key_name"; then
        pass "github.com lists ${key_name}"
    else
        fail "github.com lists ${key_name}"
    fi
    if printf '%s\n' "$login_keys_block" | grep -q "$key_name"; then
        fail "login hosts omit github key ${key_name}"
    else
        pass "login hosts omit github key ${key_name}"
    fi
done

for key_name in "${login_keys[@]}"; do
    if printf '%s\n' "$login_keys_block" | grep -q "$key_name"; then
        pass "login hosts list ${key_name}"
    else
        fail "login hosts list ${key_name}"
    fi
    if printf '%s\n' "$github_block" | grep -q "$key_name"; then
        fail "github.com omits login key ${key_name}"
    else
        pass "github.com omits login key ${key_name}"
    fi
done

if grep -q 'id_ed25519_github_laptop_huawei' "$TEMPLATE"; then
    fail "transitional underscore github key is gone"
else
    pass "transitional underscore github key is gone"
fi

if printf '%s\n' "$github_block" | grep -q 'id_ed25519_laptop-huawei-2026-10-5A' \
    && printf '%s\n' "$github_block" | grep -q 'id_ed25519_moicen-alchemy-2026-10-Nc' \
    && [[ "$(printf '%s\n' "$github_block" | grep -n 'id_ed25519_laptop-huawei-2026-10-5A' | head -n 1 | cut -d: -f1)" -lt "$(printf '%s\n' "$github_block" | grep -n 'id_ed25519_moicen-alchemy-2026-10-Nc' | head -n 1 | cut -d: -f1)" ]]; then
    pass "Nc stays behind the machine GitHub keys"
else
    fail "Nc stays behind the machine GitHub keys"
fi

if grep -q 'ci.moicen.com\|alchemy-vnc\|moicen-vnc' "$TEMPLATE"; then
    fail "removed moicen tunnel hosts stay out of the template"
else
    pass "removed moicen tunnel hosts stay out of the template"
fi

if printf '%s\n' "$moicen_block" | grep -q 'id_ed25519_moicen-alchemy-2026-10-Nc' \
    && ! printf '%s\n' "$moicen_block" | grep -q 'id_ed25519_mac-mini-2026-10-GY'; then
    pass "moicen and alchemy use only the Nc key"
else
    fail "moicen and alchemy use only the Nc key"
fi

assert_host() {
    local desc="$1"
    local pattern="$2"
    if printf '%s\n' "$login_block" | grep -q "$pattern"; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

assert_host "laptop-huawei alias exists" '^Host laptop-huawei$'
assert_host "laptop-huawei user is xiaoli" 'User xiaoli'
assert_host "mac-mini user is liyong" 'User liyong'
assert_host "company-pc keeps desktop-win alias" '^Host company-pc-win10 desktop-win$'
assert_host "company-pc hostname is the MagicDNS name" 'HostName company-pc-win10'
assert_host "company-pc user is Administrator" 'User Administrator'
assert_host "vps keeps xiaolitongxue-vps alias" '^Host vps xiaolitongxue-vps$'
assert_host "vps hostname is the MagicDNS name" 'HostName vps'
assert_host "vps user is ubuntu" 'User ubuntu'
assert_host "phone user is u0_a0" 'User u0_a0'
assert_host "phone port is 8022" 'Port 8022'
assert_host "pad user is u0_a71" 'User u0_a71'

if grep -qE '^Host vps$' "$TEMPLATE"; then
    fail "template does not add a vps host without the old alias"
else
    pass "template does not add a vps host without the old alias"
fi

phone_port_count="$(printf '%s\n' "$login_block" | grep -c 'Port 8022' || true)"
if [[ "$phone_port_count" -eq 2 ]]; then
    pass "phone and pad both use port 8022"
else
    fail "phone and pad both use port 8022 (count=${phone_port_count})"
fi

echo ""
echo "=========================================="
echo "Summary: ${PASSED} passed, ${FAILED} failed"
echo "=========================================="

exit "$FAILED"
