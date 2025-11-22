#!/bin/bash

# Function to get the MAC address for a given product name
get_mac_address() {
    local product_name="$1"
    lshw -C network | grep -A 10 "$product_name" | grep serial | awk '{print $2}'
}

# Get the MAC address of the onboard Ethernet interface
MB_ETH_MAC=$(get_mac_address "product: RTL8125 2.5GbE Controller")

# Get the MAC addresses of the Realtek PCIe interfaces
PCI_SINGLE_ETH_MACS=($(get_mac_address "product: Realtek Semiconductor Co., Ltd."))

# Get the MAC addresses of the 82576 Gigabit PCIe interfaces
PCI_DUAL_ETH_MACS=($(get_mac_address "product: 82576 Gigabit Network Connection"))

# Display detected MAC addresses for debugging
echo "Detected MAC addresses:"
echo "Onboard (RTL8125) - eth0: $MB_ETH_MAC"
echo "PCI_SINGLE_ETH_MACS: ${PCI_SINGLE_ETH_MACS[@]}"
echo "PCI_DUAL_ETH_MACS: ${PCI_DUAL_ETH_MACS[@]}"

# Wait a moment
sleep 1

# Initialize variables
PCI_ETH1_MAC=""
PCI_ETH2_MAC=""

# Filter out the onboard MAC address from PCIe MAC addresses
FILTERED_PCI_ETH_MACS=()
for mac in "${PCI_SINGLE_ETH_MACS[@]}"; do
    if [ "$mac" != "$MB_ETH_MAC" ]; then
        FILTERED_PCI_ETH_MACS+=("$mac")
    fi
done

# Assign filtered PCIe MAC addresses
PCI_ETH1_MAC="${FILTERED_PCI_ETH_MACS[0]}"
PCI_ETH2_MAC="${FILTERED_PCI_ETH_MACS[1]}"


# Check if both PCI_ETH1_MAC and PCI_ETH2_MAC are empty
if [ -z "$PCI_ETH1_MAC" ] && [ -z "$PCI_ETH2_MAC" ]; then

  echo "PCI_SINGLE_ETH_MACS are empty."

  # Filter out the onboard MAC address from DUAL PCIe MAC addresses
  FILTERED_PCI_ETH_MACS=()
  for mac in "${PCI_DUAL_ETH_MACS[@]}"; do
      if [ "$mac" != "$MB_ETH_MAC" ]; then
          FILTERED_PCI_ETH_MACS+=("$mac")
      fi
  done

  # Assign filtered PCIe MAC addresses
  PCI_ETH1_MAC="${FILTERED_PCI_ETH_MACS[0]}"
  PCI_ETH2_MAC="${FILTERED_PCI_ETH_MACS[1]}"

fi

# Display the identified PCIe MAC addresses
echo "Filtered PCI_SINGLE_ETH_MACS: ${FILTERED_PCI_ETH_MACS[@]}"
echo "PCI_ETH1_MAC: $PCI_ETH1_MAC"
echo "PCI_ETH2_MAC: $PCI_ETH2_MAC"

# Wait a moment
sleep 1

# Create udev rules file
UDEV_RULES_FILE="/etc/udev/rules.d/70-persistent-net.rules"

echo "Creating udev rules file at $UDEV_RULES_FILE..."

# Remove old udev rules (optional, if you want to clean up existing rules)
sudo rm -f $UDEV_RULES_FILE

# Write udev rules to the file
cat <<EOL | sudo tee $UDEV_RULES_FILE
# Udev rules to set persistent names for network interfaces

# Onboard interface (RTL8125) as eth0
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$MB_ETH_MAC", NAME="eth0"
EOL

# Add PCIe interface rules if they exist
if [ ! -z "$PCI_ETH1_MAC" ]; then
    cat <<EOL | sudo tee -a $UDEV_RULES_FILE
# PCIe interface (Realtek) as eth1
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$PCI_ETH1_MAC", NAME="eth1"
EOL
fi

if [ ! -z "$PCI_ETH2_MAC" ]; then
    cat <<EOL | sudo tee -a $UDEV_RULES_FILE
# PCIe interface (Realtek) as eth2
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$PCI_ETH2_MAC", NAME="eth2"
EOL
fi

echo "Udev rules created successfully."

# Disable predictable network interface names
sudo ln -sf /dev/null /etc/systemd/network/99-default.link

# Bring down the network interfaces
echo "Bringing down network interfaces..."
sudo ip link set eth0 down || true
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip link set eth1 down || true
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip link set eth2 down || true
fi

# Rename interfaces to temporary names
sudo ip link set eth0 name temp0 || true
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip link set eth1 name temp1 || true
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip link set eth2 name temp2 || true
fi

# Reload udev rules
echo "Reloading udev rules..."
sudo udevadm control --reload-rules

# Trigger udev rules to apply the new names
echo "Triggering udev rules..."
sudo udevadm trigger --action=add

# Wait a moment for the rules to apply
sleep 2

# Rename interfaces back to desired names
sudo ip link set temp0 name eth0 || true
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip link set temp1 name eth1 || true
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip link set temp2 name eth2 || true
fi

# Bring up the network interfaces
echo "Bringing up network interfaces..."
sudo ip link set eth0 up || true
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip link set eth1 up || true
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip link set eth2 up || true
fi

# Flush existing IP addresses to avoid conflicts
sudo ip addr flush dev eth0 || true
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip addr flush dev eth1 || true
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip addr flush dev eth2 || true
fi

# Assign static IP addresses
echo "Assigning static IP addresses..."
sudo ip addr add 120.120.120.10/24 dev eth0
if [ ! -z "$PCI_ETH1_MAC" ]; then
    sudo ip addr add 192.168.10.11/24 dev eth1
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    sudo ip addr add 192.168.12.11/24 dev eth2
fi

# Verify the IP addresses
echo "Here are the new IP addresses:"
ip addr show dev eth0
if [ ! -z "$PCI_ETH1_MAC" ]; then
    ip addr show dev eth1
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    ip addr show dev eth2
fi

# Display the new udev rules for verification
echo "Here are the new udev rules:"
cat $UDEV_RULES_FILE

# Debugging steps to ensure udev rules are applied
echo "Debugging udev rules..."
echo "Checking for the current udev rule status..."
udevadm info --query=all --path=/sys/class/net/eth0
if [ ! -z "$PCI_ETH1_MAC" ]; then
    udevadm info --query=all --path=/sys/class/net/eth1
fi
if [ ! -z "$PCI_ETH2_MAC" ]; then
    udevadm info --query=all --path=/sys/class/net/eth2
fi

# Check system logs for udev events
echo "Checking system logs for udev events..."
journalctl -u systemd-udevd | tail -n 20
