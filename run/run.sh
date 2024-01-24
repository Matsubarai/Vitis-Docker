#!/bin/bash
xhost +local:root

docker run \
    #--interactive \
    #--tty \
    --detach \
    --net host \
    --rm \
    --name vitis \
    --env TZ=Asia/Shanghai \
    --env DISPLAY=${DISPLAY} \
    --env QT_X11_NO_MITSHM=1 \
    --env NO_AT_BRIDGE=1 \
    --env LIBGL_ALWAYS_INDIRECT=1 \
    --env HOST_USER=${USER} \
    --env HOST_UID=$(id -u ${USER}) \
    --env HOST_GROUP=${USER} \
    --env HOST_GID=$(id -g ${USER}) \
    #--env XILINXD_LICENSE_FILE=/tools/Xilinx/Xilinx.lic \
    --volume /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --volume /tools/Xilinx:/tools/Xilinx \
    ghcr.io/Matsubarai/vitis:${XILINX_VERSION} \

