#/bin/bash
image=${1}
cont_name=${2}

if [ -z "$image" ]
then
        echo "Provide an image name (1)"
        exit
fi


if [ -z "$cont_name" ]
then
        echo "Provide an container name 2)"
        exit
fi


#docker network create -d bridge my-bridge-net
#docker network inspect my-bridge-net



echo "Testing $container from image $image"

echo "docker run -d -P --name $cont_name --network my-bridge-net $image"
#docker run -d -P --name $cont_name $image
docker run -d --name $cont --network my-bridge-net $image

echo "cont_info=$(docker inspect --format '{{ .NetworkSettings.Ports }}' $cont_name)"
cont_info="$(docker inspect --format '{{ .NetworkSettings.Ports }}' $cont_name)"
echo "Container Info: $cont_info"
echo

echo "cont_network=$(echo $cont_info | awk -F '{' '{print $2}')"
cont_network=$(echo $cont_info | awk -F '{' '{print $2}')
echo "Container Network: $cont_network"
echo

echo  "cont_ip=${cont_network::-2}"
cont_ip="${cont_network::-2}"
cont_ip=$(echo $cont_ip | tr " " :)


# curl ifconfig.me
echo "The container IP is: $cont_import"
echo "Starting test of connectivity between host and container"
echo "Getting Host IP..."

hst="$(hostname -I | awk '{print $1}')"
echo "Host IP: $hst"
echo "Testing connectivity from $hst to $cont_ip"
curl "$cont_ip"

echo "Test compled"
docker network create -d macvlan   --subnet=192.168.69.0/24   --gateway=192.168.69.1   -o parent=docker0 my-macvlan-net 
docker network connect my-bridge-net-03 whoami_multiple_bridge-01
