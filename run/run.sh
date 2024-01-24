#!/bin/bash
xhost +local:root
EXC="true"
PUB="false"
IMG="ghcr.io/Matsubarai/vitis:${XILINX_VERSION}"
while getopts ":d:p:i:v:eh" optname
do
	case "$optname" in
		"d")
			DEVICE=$OPTARG
			;;
		"s")
			EXC="false"
			;;
        "p")
            PUB="true"
			EXPOSE_PORT=8888
			;;
		"i")
			IMG="$OPTARG"
			;;
		"v")
			MNT="$MNT --volume $OPTARG" 
			;;
		"h")
			echo "USAGE: env_alloc [-d <DeviceID[,...]=NULL>] [-s (NO_EXCLUSION_FLAG)] [-i <IMAGE_NAME>]                    "
			exit 0
			;;
		":")
			echo "No argument value for option -$OPTARG"
			exit 1
			;;
		"?")
			echo "Unknown option $OPTARG"
			exit 1
			;;
		*)
			echo "Unknown error while processing options"
			exit 1
			;;
	esac
done
if [ $MNT ]
then
	echo "custom mount point:$MNT"
fi
FLAGS="--detach --net host --rm --name $USER-env --runtime=xilinx --env XILINX_VISIBLE_DEVICES=$DEVICE --env XILINX_DEVICE_EXCLUSIVE=$EXC --env TZ=Asia/Shanghai --env DISPLAY=${DISPLAY} --env QT_X11_NO_MITSHM=1 --env NO_AT_BRIDGE=1 --env LIBGL_ALWAYS_INDIRECT=1 --env HOST_USER=${USER} --env HOST_UID=$(id -u ${USER}) --env HOST_GROUP=${USER} --env HOST_GID=$(id -g ${USER}) --volume /tmp/.X11-unix:/tmp/.X11-unix:rw --volume /tools/Xilinx:/tools/Xilinx -v /home/$USER:/data -v /usr/local/etc:/usr/local/etc $MNT"
docker inspect $USER-env > /dev/null 2>&1
if [ $? -eq 0 ]
then
	echo "Environment exists. You can execute or deallocate it."
	exit 0
fi

if [ $PUB = "true" ]
then
	PORT=`head -n 1 /usr/local/etc/port_pool`
	cp /usr/local/etc/port_pool ./.port_pool.temp
	sed -i '1d' ./.port_pool.temp
	cat ./.port_pool.temp > /usr/local/etc/port_pool
	rm ./.port_pool.temp

	if [ $PORT ]
	then
		echo "Publish $APP port $EXPOSE_PORT/tcp -> localhost:$PORT"
		docker run -p $PORT:$EXPOSE_PORT --env PORT=$PORT $FLAGS $IMG sleep infinity
	else
		echo "No valid port for publishing, use a random port"
		docker run -P $FLAGS $IMG sleep infinity
	fi
else
	echo "In command-line mode"
	docker run $FLAGS $IMG sleep infinity
fi

if [ $? -ne 0 ]
then
	if [ $PORT ]
	then
		echo $PORT >> /usr/local/etc/port_pool
	fi
	exit 1
fi

if [ $DEVICE ]
then
	at -f /usr/local/bin/env_dealloc now +2 hours 2>&1 | grep -o '[0-9]\+' | head -1 > /usr/local/etc/timer_id.$USER
	echo "Device[$DEVICE] will be released after 2 hours."
fi

docker run \
    #--interactive \
    #--tty \
    --detach \
    --net host \
    --rm \
    --name $USER-env \
    --env TZ=Asia/Shanghai \
    --env DISPLAY=${DISPLAY} \
    --env QT_X11_NO_MITSHM=1 \
    --env NO_AT_BRIDGE=1 \
    --env LIBGL_ALWAYS_INDIRECT=1 \
    --env HOST_USER=${USER} \
    --env HOST_UID=$(id -u ${USER}) \
    --env HOST_GROUP=${USER} \
    --env HOST_GID=$(id -g ${USER}) \
    --env PORT=${PORT}
    #--env XILINXD_LICENSE_FILE=/tools/Xilinx/Xilinx.lic \
    --volume /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --volume /tools/Xilinx:/tools/Xilinx \
    ghcr.io/Matsubarai/vitis:${XILINX_VERSION} \

