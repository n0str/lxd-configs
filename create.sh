RED='\033[0;31m'
NC='\033[0m'
read -r -p "Provide container name: " NAME
lxc init basic-image $NAME -p default
read -r -p "Do you want to create a network segment? [y/N] " response 
case "$response" in
    [yY][eE][sS]|[yY])

        echo
        echo "Current networks"
        echo
        ip -4 -o addr | awk -v red="$RED" -v nc="$NC" '{print red $2 nc": "$4}'
        echo
        read -r -p "Provide network name (name-br): " NETWORK_NAME
        read -r -p "Provide bridge interface IP/Mask (10.42.0.1/24): " NETWORK_SEGMENT
        EXAMPLE_IP=`echo $NETWORK_SEGMENT | awk '{split($0, a, "/"); print a[1]}'`
        read -r -p "Provide image IP ($EXAMPLE_IP): " IP
        lxc network create $NETWORK_NAME ipv6.address=none ipv4.address=$NETWORK_SEGMENT ipv6.nat=false ipv4.nat=false ipv4.firewall=false ipv6.firewall=false
        lxc network attach $NETWORK_NAME $NAME eth0
        lxc config device set $NAME eth0 ipv4.address $IP
        iptables -A FORWARD -s $NETWORK_SEGMENT -i $NETWORK_NAME -o ens3 -j ACCEPT
        iptables -A FORWARD -i $NETWORK_NAME -j DROP
        ;;
    *)
        lxc list
        lxc network attach pofig-br $NAME eth0
        read -r -p "Provide image IP: " IP
        lxc config device set $NAME eth0 ipv4.address $IP
        ;;
esac

read -r -p "Provide port for SSH (10022): " SSH_PORT
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport $SSH_PORT -j DNAT --to $IP:22
