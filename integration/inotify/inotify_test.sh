#!/bin/bash
#
# Copyright (c) 2020-2021 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#
# This will test the default_vcpus
# feature is working properly

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace

name="${name:-inotify_test}"
IMAGE="${IMAGE:-docker.apple.com/eric_g_ernst/inotify:latest}"

CONTAINER_NAME="${CONTAINER_NAME:-test}"
PAYLOAD_ARGS="${PAYLOAD_ARGS:-inotifywait --timeout 8 /certs}"

function test_inotify() {

	sudo ctr c delete "${CONTAINER_NAME}" || true
	sudo ctr c rm "${CONTAINER_NAME}" || true

	# Create temporary mount for testing inotify
        WORKDIR=`mktemp -d`
        MOUNTDIR="${WORKDIR}"/kubernetes.io~secret
        mkdir "${MOUNTDIR}"
        secret="${MOUNTDIR}"/token
        echo "super-secret" > "${secret}"

        CONTAINERD_RUNTIME="io.containerd.kata.v2"
	TOML_PATH="/etc/kata-containers/configuration-qemu.toml"
        #sudo ctr image pull "${IMAGE}"
        [ $? != 0 ] && die "Unable to get image $IMAGE"
        sudo ctr run --rm --runtime="${CONTAINERD_RUNTIME}" --runtime-config-path "${TOML_PATH}" --mount type=bind,src="${secret}",dst=/certs,options=rbind:ro --detach "${IMAGE}" "${CONTAINER_NAME}" sh -c "${PAYLOAD_ARGS}"

        echo "super-secret-update" > "${secret}"

	sleep 8

	result=$(sudo ctr t delete "${CONTAINER_NAME}" 2>&1)

	echo $result | grep -qv error\ code\ 2 

	sudo ctr c delete "${CONTAINER_NAME}" || true
	sudo ctr c rm "${CONTAINER_NAME}" || true
}


test_inotify
