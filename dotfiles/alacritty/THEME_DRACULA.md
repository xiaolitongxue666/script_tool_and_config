# Alacritty Dracula 主题配置

## 主题说明

Dracula 是一个流行的暗色主题，适用于多种终端和编辑器。

**参考**: [Dracula Theme](https://draculatheme.com/alacritty)

## 配置方法

### 1. 主题文件位置

主题文件已下载到：
```
~/.config/alacritty/themes/dracula.toml
```

### 2. 配置文件导入

在 `~/.config/alacritty/alacritty.toml` 中已添加导入：

```toml
import = [
  "~/.config/alacritty/themes/dracula.toml",
]
```

### 3. 应用主题

重启 Alacritty 终端即可应用 Dracula 主题。

## 主题颜色

Dracula 主题的主要颜色：

- **背景**: `#282a36` (深灰蓝)
- **前景**: `#f8f8f2` (浅灰白)
- **主要颜色**:
  - 红色: `#ff5555`
  - 绿色: `#50fa7b`
  - 黄色: `#f1fa8c`
  - 蓝色: `#bd93f9`
  - 紫色: `#ff79c6`
  - 青色: `#8be9fd`

## 自定义配置

如果需要在使用 Dracula 主题的同时自定义某些颜色，可以在 `alacritty.toml` 中主题导入之后添加覆盖配置：

```toml
import = [
  "~/.config/alacritty/themes/dracula.toml",
]

# 覆盖主题中的某些颜色
[colors.cursor]
  text = "CellBackground"
  cursor = "#f8f8f2"
```

## 其他主题

如果需要切换到其他主题，可以：

1. 从 [Alacritty Theme](https://github.com/alacritty/alacritty-theme) 下载主题文件
2. 保存到 `~/.config/alacritty/themes/` 目录
3. 更新 `import` 配置

## 故障排除

### 主题未生效

1. 检查主题文件是否存在：
   ```bash
   ls ~/.config/alacritty/themes/dracula.toml
   ```

2. 检查配置文件语法：
   ```bash
   /Applications/Alacritty.app/Contents/MacOS/alacritty --print-events 2>&1 | grep -i error
   ```

3. 确认导入路径正确（支持 `~` 和绝对路径）

### 恢复默认主题

删除或注释掉 `import` 行即可恢复默认配置。

