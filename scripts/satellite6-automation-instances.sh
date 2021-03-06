function remove_instance () {
    echo "========================================"
    echo " Remove any running instances if any of ${TARGET_IMAGE} virsh domain."
    echo "========================================"
    set +e
    ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh destroy ${TARGET_IMAGE}
    ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh undefine ${TARGET_IMAGE}
    ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh vol-delete --pool default /var/lib/libvirt/images/${TARGET_IMAGE}.img
    set -e
}

function setup_instance () {
    # Provision the instance using satellite6 base image as the source image.
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" \
    snap-guest -b "${SOURCE_IMAGE}" -t "${TARGET_IMAGE}" --hostname "${SERVER_HOSTNAME}" \
    -m "${VM_RAM}" -c "${VM_CPU}" -d "${VM_DOMAIN}" -f -n bridge="${BRIDGE}" --static-ipaddr "${IPADDR}" \
    --static-netmask "${NETMASK}" --static-gateway "${GATEWAY}"

    # Let's wait for 60 secs for the instance to be up and along with it it's services
    sleep 60

    # Restart Satellite6 service for a clean state of the running instance.
    ssh -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" 'katello-service restart'
}

if ! [[ ${SATELLITE_DISTRIBUTION} =~ UPSTREAM|KOJI ]]; then
    # Provisioning jobs TARGET_IMAGE becomes the SOURCE_IMAGE for Tier and RHAI jobs.
    # source-image at this stage for example: qe-sat63-rhel7-base
    export SOURCE_IMAGE="${TARGET_IMAGE}"
    # target-image at this stage for example: qe-sat63-rhel7-tier1
    export TARGET_IMAGE="${TARGET_IMAGE%%-base}-${ENDPOINT}"

    remove_instance
    setup_instance
fi
