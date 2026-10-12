# 设置用户名和邮箱
#git config --global user.name "Firstname Lastname"
#git config --global user.email "your_email@example.com"

# 显示用户名和邮箱
git config user.name
git config user.email

# 设置 UI 颜色
git config --global color.ui auto

# 设置 SSH 密钥。当前仓库的做法见 docs/SSH_KEY_ROTATION.md：
# 文件名 id_ed25519_<Tailscale 名>-<YYYY-MM>-<指纹末两位>
# 本机 GitHub：~/.ssh/id_ed25519_desktop-win-2026-10-C4
# Mac GitHub：~/.ssh/id_ed25519_mac-mini-2026-10-5s
# moicen.com 与 alchemy-studio.cn 共用 id_ed25519_moicen-alchemy-2026-10-Nc，也已加到 GitHub
# 登录 VPS / 手机 / Mac / 平板用另外的密钥，见 docs/DEVICE_ACCESS.md
# 密钥指纹是:
# 指纹值 your_email@example.com
# 密钥的随机艺术图像是:
# +--[ RSA 2048]----+
# | .+ + |
# | = o O . |

# 添加 SSH 密钥
cat ~/.ssh/id_ed25519_desktop-win-2026-10-C4.pub
# ssh-rsa  "公钥" your_email@example.com
ssh -T git@github.com
# 无法确认主机 'github.com (207.97.227.239)' 的真实性
# RSA 密钥指纹是 指纹值
# 您确定要继续连接吗 (yes/no)?  输入 yes 

# 如果成功将显示以下内容
# Hi hirocastest! 您已成功通过身份验证，但 GitHub 不提供 shell 访问权限
