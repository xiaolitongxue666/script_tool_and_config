# Alacritty 警告修复说明

## 问题总结

启动 Alacritty 时出现的警告：

1. **`WARNING: terminal is not fully functional`** - Terminfo 未安装
2. **配置警告** - 使用了已废弃的配置项

## 已修复的配置项

### 1. `live_config_reload`
- **旧配置**: `live_config_reload = true` (根级别)
- **新配置**: `[general]` 部分下的 `live_config_reload = true`
- **状态**: ✅ 已修复

### 2. 已废弃的配置项（已注释）
以下配置项在新版本中已不再使用，已注释掉：

- `use_thin_strokes` - 细笔画字体渲染（已废弃）
- `decorations` - 窗口装饰（应使用 `[window.decorations]`）
- `opacity` - 背景不透明度（应使用 `[window.opacity]`）
- `startup_mode` - 启动模式（应使用 `[window.startup_mode]`）
- `title` - 窗口标题（应使用 `[window.title]`）
- `dynamic_title` - 动态标题（新版本默认启用）

## Terminfo 安装

### 问题
`WARNING: terminal is not fully functional` 表示 terminfo 数据库中没有 Alacritty 的终端信息。

### 解决方案

#### 方法 1: 使用 alacritty migrate（推荐）
```bash
/Applications/Alacritty.app/Contents/MacOS/alacritty migrate
```

#### 方法 2: 手动安装 Terminfo

1. **下载 terminfo 文件**:
```bash
cd /tmp
curl -L -o alacritty.info "https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info"
```

2. **安装到系统**（需要 sudo 权限）:
```bash
sudo tic -xe alacritty,alacritty-direct alacritty.info
```

3. **验证安装**:
```bash
infocmp alacritty
```

如果命令成功执行并显示终端信息，说明安装成功。

#### 方法 3: 安装到用户目录（不需要 sudo）

如果无法使用 sudo，可以安装到用户目录：

```bash
# 创建用户 terminfo 目录
mkdir -p ~/.terminfo/61

# 下载并编译到用户目录
cd /tmp
curl -L -o alacritty.info "https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info"
tic -xe alacritty,alacritty-direct -o ~/.terminfo alacritty.info

# 验证
infocmp alacritty
```

## 配置文件更新

配置文件已更新为符合 Alacritty 0.16.1 的格式：

- ✅ `live_config_reload` 已移至 `[general]` 部分
- ✅ 所有废弃的配置项已注释
- ✅ 配置文件已通过 `alacritty migrate` 验证

## 验证修复

重启 Alacritty 后，应该不再看到警告信息。如果仍有警告，请检查：

1. 配置文件位置：`~/.config/alacritty/alacritty.toml`
2. Terminfo 是否安装：运行 `infocmp alacritty`
3. Alacritty 版本：运行 `alacritty --version`

## 参考

- [Alacritty 官方文档](https://github.com/alacritty/alacritty)
- [配置文件迁移指南](https://github.com/alacritty/alacritty/blob/master/INSTALL.md)

