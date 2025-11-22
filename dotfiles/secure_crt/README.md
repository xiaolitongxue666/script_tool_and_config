# SecureCRT 配置

SecureCRT 是一个终端模拟器和 SSH 客户端，主要用于 Windows 系统。

## 配置文件结构

```
secure_crt/
├── SecureCRTV8_VM_Login_TOP.vbs    # VBScript 自动化脚本
├── install.sh                       # 自动安装脚本（Windows）
└── README.md                        # 本文件
```

## 安装方法

### 使用安装脚本

在 Windows 的 Git Bash 或 MSYS2 中运行：

```bash
cd dotfiles/secure_crt
chmod +x install.sh
./install.sh
```

### 手动安装

1. 打开 SecureCRT
2. 进入 "Options" > "Global Options" > "General" > "Configuration Paths"
3. 找到配置目录（通常是 `%APPDATA%\VanDyke\Config`）
4. 复制配置文件到该目录

## 配置文件说明

### SecureCRTV8_VM_Login_TOP.vbs

VBScript 自动化脚本，用于：
- 自动登录到虚拟机
- 执行 `top -d 1` 命令
- 监控系统资源

使用方法：
1. 在 SecureCRT 中打开脚本菜单
2. 选择 "Run Script"
3. 选择 `SecureCRTV8_VM_Login_TOP.vbs`

### 配置备份和恢复

如果需要备份 SecureCRT 配置：

1. **导出配置**：
   - 打开 SecureCRT
   - 进入 "Options" > "Export Settings"
   - 选择导出位置和文件名

2. **导入配置**：
   - 打开 SecureCRT
   - 进入 "Options" > "Import Settings"
   - 选择之前导出的配置文件

**注意**: 导出的配置文件可能包含敏感信息（如许可证密钥、会话密码等），请妥善保管。

## 配置文件位置

- **Windows**: `%APPDATA%\VanDyke\Config\`
- **完整路径**: `C:\Users\<用户名>\AppData\Roaming\VanDyke\Config\`

## 系统要求

- **操作系统**: Windows
- **软件**: SecureCRT

## 参考链接

- [SecureCRT 官网](https://www.vandyke.com/products/securecrt/)
- [SecureCRT 文档](https://www.vandyke.com/support/securecrt/documentation.html)

