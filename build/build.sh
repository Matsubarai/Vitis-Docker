#!/bin/bash
XILINX_VERSION="2022.2"
docker build \
    --tag ghcr.io/matsubarai/Vitis-Docker/vitis:${XILINX_VERSION} \
    .

