#!/bin/bash
# ZMK Local Build Script using Docker (with caching)

BOARD="nice_nano_v2"
SHIELD_LEFT="crosses_left"
SHIELD_RIGHT="crosses_right"
ZMK_WORKSPACE=".zmk-workspace"

mkdir -p firmware
mkdir -p "${ZMK_WORKSPACE}"

init_workspace() {
    echo "Initializing ZMK workspace (this only needs to run once)..."
    
    docker run --rm \
        -v "${PWD}/${ZMK_WORKSPACE}:/workspace" \
        -v "${PWD}/config:/workspace/config:ro" \
        -w /workspace \
        zmkfirmware/zmk-dev-arm:stable \
        bash -c "
            if [ ! -d zmk ]; then
                echo 'Initializing west workspace...'
                west init -l config
                west update
                west zephyr-export
                pip3 install --user -r zmk/app/scripts/requirements.txt
                echo 'Workspace initialized!'
            else
                echo 'Workspace exists, updating...'
                west update
                west zephyr-export
            fi
        "
    
    touch "${ZMK_WORKSPACE}/.west_update_marker"
    echo "ZMK workspace ready in ${ZMK_WORKSPACE}/"
}

build_side() {
    local side=$1
    local shield=$2
    local extra_args=$3
    
    echo "Building $side side..."
    
    docker run --rm \
        -v "${PWD}/${ZMK_WORKSPACE}:/workspace" \
        -v "${PWD}/config:/workspace/config:ro" \
        -v "${PWD}/firmware:/workspace/firmware" \
        -w /workspace \
        zmkfirmware/zmk-dev-arm:stable \
        bash -c "
            # Ensure zephyr is exported
            west zephyr-export 2>/dev/null || true
            
            # Build
            west build -s zmk/app -b ${BOARD} -d build/${side} -p auto -- \
                -DSHIELD=${shield} \
                -DZMK_CONFIG=/workspace/config \
                ${extra_args}
            
            # Copy output
            cp build/${side}/zephyr/zmk.uf2 /workspace/firmware/${BOARD}-${shield}.uf2
        "
    
    if [ $? -eq 0 ]; then
        echo "✓ Built: firmware/${BOARD}-${shield}.uf2"
    else
        echo "✗ Build failed for $side"
        return 1
    fi
}

check_west_update() {
    # Check if west update is needed by comparing manifest modification time
    # with a marker file
    
    local manifest_file="${PWD}/config/west.yml"
    local marker_file="${ZMK_WORKSPACE}/.west_update_marker"
    local needs_update=false
    
    if [ ! -f "${marker_file}" ]; then
        needs_update=true
    elif [ "${manifest_file}" -nt "${marker_file}" ]; then
        needs_update=true
    fi
    
    if [ "$needs_update" = true ]; then
        echo "West manifest has changed, updating workspace..."
        docker run --rm \
            -v "${PWD}/${ZMK_WORKSPACE}:/workspace" \
            -v "${PWD}/config:/workspace/config:ro" \
            -w /workspace \
            zmkfirmware/zmk-dev-arm:stable \
            bash -c "
                west update
                west zephyr-export
            "
        
        touch "${marker_file}"
        echo "West workspace updated."
    fi
}

check_workspace() {
    if [ ! -d "${ZMK_WORKSPACE}/zmk" ]; then
        echo "ZMK workspace not found. Running init first..."
        init_workspace
    else
        check_west_update
    fi
}

case "${1}" in
    init)
        init_workspace
        ;;
    left)
        check_workspace
        build_side "left" "$SHIELD_LEFT"
        ;;
    right)
        check_workspace
        build_side "right" "$SHIELD_RIGHT" "-DCONFIG_ZMK_STUDIO=y"
        ;;
    reset)
        check_workspace
        build_side "reset" "settings_reset"
        ;;
    all)
        check_workspace
        build_side "left" "$SHIELD_LEFT"
        build_side "right" "$SHIELD_RIGHT" "-DCONFIG_ZMK_STUDIO=y"
        build_side "reset" "settings_reset"
        ;;
    clean)
        echo "Cleaning build directories..."
        rm -rf "${ZMK_WORKSPACE}/build"
        rm firmware/*.uf2
        echo "Done. Run './build-local.sh all' to rebuild."
        ;;
    purge)
        echo "Removing entire ZMK workspace..."
        rm -rf "${ZMK_WORKSPACE}"
        rm -rf firmware
        echo "Done. Run './build-local.sh init' to reinitialize."
        ;;
    update)
        echo "Forcing west update..."
        docker run --rm \
            -v "${PWD}/${ZMK_WORKSPACE}:/workspace" \
            -v "${PWD}/config:/workspace/config:ro" \
            -w /workspace \
            zmkfirmware/zmk-dev-arm:stable \
            bash -c "
                west update
                west zephyr-export
            "
        touch "${ZMK_WORKSPACE}/.west_update_marker"
        echo "West workspace updated."
        ;;
    "")
        echo "Usage: $0 [init|left|right|reset|all|clean|purge|update]"
        echo ""
        echo "Commands:"
        echo "  init   - Initialize/update ZMK workspace (run once)"
        echo "  left   - Build left side firmware"
        echo "  right  - Build right side firmware (with ZMK Studio)"
        echo "  reset  - Build settings_reset firmware"
        echo "  all    - Build all firmware"
        echo "  clean  - Clean build directories (keep workspace)"
        echo "  purge  - Delete everything, start fresh"
        echo "  update - Force west update (auto-checked before builds)"
        exit 1
        ;;
esac

echo ""
echo "Firmware files:"
ls -la firmware/*.uf2 2>/dev/null || echo "No firmware files yet"
