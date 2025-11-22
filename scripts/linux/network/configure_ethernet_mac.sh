#!/bin/bash

# 根据产品名称获取 MAC 地址的函数
get_mac_address() {
    local product_name="$1"
    lshw -C network | grep -A 10 "$product_name" | grep serial | awk '{print $2}'
}

# 获取板载以太网接口的 MAC 地址
MB_ETH_MAC=$(get_mac_address "product: RTL8125 2.5GbE Controller")

# 获取 Realtek PCIe 接口的 MAC 地址
PCI_SINGLE_ETH_MACS=($(get_mac_address "product: Realtek Semiconductor Co., Ltd."))

# 获取 82576 千兆 PCIe 接口的 MAC 地址
PCI_DUAL_ETH_MACS=($(get_mac_address "product: 82576 Gigabit Network Connection"))

# 显示检测到的 MAC 地址（用于调试）
echo "检测到的 MAC 地址:"
echo "板载 (RTL8125) - eth0: $MB_ETH_MAC"
echo "PCI_SINGLE_ETH_MACS: ${PCI_SINGLE_ETH_MACS[@]}"
echo "PCI_DUAL_ETH_MACS: ${PCI_DUAL_ETH_MACS[@]}"

# 等待片刻
sleep 1

# 初始化变量
PCI_ETH1_MAC=""
PCI_ETH2_MAC=""

# 从 PCIe MAC 地址中过滤掉板载 MAC 地址
FILTERED_PCI_ETH_MACS=()
for mac in "${PCI_SINGLE_ETH_MACS[@]}"; do
    if [ "$mac" != "$MB_ETH_MAC" ]; then
        FILTERED_PCI_ETH_MACS+=("$mac")
    fi
done

# 分配过滤后的 PCIe MAC 地址
PCI_ETH1_MAC="${FILTERED_PCI_ETH_MACS[0]}"
PCI_ETH2_MAC="${FILTERED_PCI_ETH_MACS[1]}"


# 检查 PCI_ETH1_MAC 和 PCI_ETH2_MAC 是否都为空
if [ -z "$PCI_ETH1_MAC" ] && [ -z "$PCI_ETH2_MAC" ]; then

  echo "PCI_SINGLE_ETH_MACS 为空。"

  # 从双 PCIe MAC 地址中过滤掉板载 MAC 地址
  FILTERED_PCI_ETH_MACS=()
  for mac in "${PCI_DUAL_ETH_MACS[@]}"; do
      if [ "$mac" != "$MB_ETH_MAC" ]; then
          FILTERED_PCI_ETH_MACS+=("$mac")
      fi
  done

  # 分配过滤后的 PCIe MAC 地址
  PCI_ETH1_MAC="${FILTERED_PCI_ETH_MACS[0]}"
  PCI_ETH2_MAC="${FILTERED_PCI_ETH_MACS[1]}"

fi

# 显示识别出的 PCIe MAC 地址
echo "过滤后的 PCI_SINGLE_ETH_MACS: ${FILTERED_PCI_ETH_MACS[@]}"
echo "PCI_ETH1_MAC: $PCI_ETH1_MAC"
echo "PCI_ETH2_MAC: $PCI_ETH2_MAC"

# 等待片刻
sleep 1

# 创建 udev 规则文件
UDEV_RULES_FILE="/etc/udev/rules.d/70-persistent-net.rules"

echo "正在创建 udev 规则文件: $UDEV_RULES_FILE..."

# 删除旧的 udev 规则（可选，如果需要清理现有规则）
sudo rm -f $UDEV_RULES_FILE

# 将 udev 规则写入文件
cat <<EOL | sudo tee $UDEV_RULES_FILE
# 为网络接口设置持久名称的 Udev 规则

# 板载接口 (RTL8125) 作为 eth0
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$MB_ETH_MAC", NAME="eth0"
EOL

# 如果 PCIe 接口存在，添加 PCIe 接口规则
if [ ! -z "$PCI_ETH1_MAC" ]; then
    cat <<EOL | sudo tee -a $UDEV_RULES_FILE
# PCIe 接口 (Realtek) 作为 eth1
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$PCI_ETH1_MAC", NAME="eth1"
EOL
fi

if [ ! -z "$PCI_ETH2_MAC" ]; then
    cat <<EOL | sudo tee -a $UDEV_RULES_FILE
# PCIe 接口 (Realtek) 作为 eth2
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$PCI_ETH2_MAC", NAME="eth2"
EOL
fi

echo "Udev 规则创建成功。"

# 禁用可预测的网络接口名称
sudo ln -sf /dev/null /etc/systemd/network/99-default.link

# 关闭网络接口
echo "正在关闭网络接口..."
sudo ip link set eth0 down || true
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip link set eth1 down || true
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip link set eth2 down || true
fi

# 将接口重命名为临时名称
sudo ip link set eth0 name temp0 || true
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip link set eth1 name temp1 || true
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip link set eth2 name temp2 || true
fi

# 重新加载 udev 规则
echo "正在重新加载 udev 规则..."
sudo udevadm control --reload-rules

# 触发 udev 规则以应用新名称
echo "正在触发 udev 规则..."
sudo udevadm trigger --action=add

# 等待片刻以便规则生效
sleep 2

# 将接口重命名回所需名称
sudo ip link set temp0 name eth0 || true
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip link set temp1 name eth1 || true
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip link set temp2 name eth2 || true
fi

# 启动网络接口
echo "正在启动网络接口..."
sudo ip link set eth0 up || true
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip link set eth1 up || true
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip link set eth2 up || true
fi

# 清空现有 IP 地址以避免冲突
sudo ip addr flush dev eth0 || true
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip addr flush dev eth1 || true
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip addr flush dev eth2 || true
fi

# 分配静态 IP 地址
echo "正在分配静态 IP 地址..."
sudo ip addr add 120.120.120.10/24 dev eth0
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip addr add 192.168.10.11/24 dev eth1
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip addr add 192.168.12.11/24 dev eth2
fi

# 验证 IP 地址
echo "新的 IP 地址如下:"
ip addr show dev eth0
if [ ! -z "$PCI_ETH1_MAC" ]; then
    ip addr show dev eth1
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    ip addr show dev eth2
fi

# 显示新的 udev 规则以供验证
echo "新的 udev 规则如下:"
cat $UDEV_RULES_FILE

# 调试步骤以确保 udev 规则已应用
echo "正在调试 udev 规则..."
echo "检查当前 udev 规则状态..."
udevadm info --query=all --path=/sys/class/net/eth0
if [ ! -z "$PCI_ETH1_MAC" ]; then
    udevadm info --query=all --path=/sys/class/net/eth1
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    udevadm info --query=all --path=/sys/class/net/eth2
fi

# 检查系统日志中的 udev 事件
echo "正在检查系统日志中的 udev 事件..."
journalctl -u systemd-udevd | tail -n 20
