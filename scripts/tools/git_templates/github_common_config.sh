# 设置用户名和邮箱
#git config --global user.name "Firstname Lastname"
#git config --global user.email "your_email@example.com"

# 显示用户名和邮箱
git config user.name
git config user.email

# 设置 UI 颜色
git config --global color.ui auto

# 设置 SSH 密钥
ssh-keygen -t rsa -C "your_email@example.com"
# 生成公钥/私钥 RSA 密钥对
# 输入保存密钥的文件
# (/Users/your_user_directory/.ssh/id_rsa):  "按 Enter"
# 输入密码短语（空表示无密码）:  "输入密码"
# 再次输入相同的密码短语:  "再次输入密码"

# 现在应该显示以下文本
# 您的身份已保存在 /Users/your_user_directory/.ssh/id_rsa
# 您的公钥已保存在 /Users/your_user_directory/.ssh/id_rsa.pub
# 密钥指纹是:
# 指纹值 your_email@example.com
# 密钥的随机艺术图像是:
# +--[ RSA 2048]----+
# | .+ + |
# | = o O . |

# 添加 SSH 密钥
cat ~/.ssh/id_rsa.pub
# ssh-rsa  "公钥" your_email@example.com
ssh -T git@github.com
# 无法确认主机 'github.com (207.97.227.239)' 的真实性
# RSA 密钥指纹是 指纹值
# 您确定要继续连接吗 (yes/no)?  输入 yes 

# 如果成功将显示以下内容
# Hi hirocastest! 您已成功通过身份验证，但 GitHub 不提供 shell 访问权限
