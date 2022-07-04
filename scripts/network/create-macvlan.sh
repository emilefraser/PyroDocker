# Macvlan  (-o macvlan_mode= Defaults to Bridge mode if not specified)
    #--aux-address 'host=193.168.1.223'
docker network create -d macvlan -o parent=eno1 \
    --subnet 192.168.68.0/24 \
    --gateway 192.168.68.1  \
    --ip-range "192.168.68.192/27" \
    delaporte_macveno1_net
