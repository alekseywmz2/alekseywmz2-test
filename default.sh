#!/bin/bash

# This file will be sourced in init.sh

# https://raw.githubusercontent.com/ai-dock/comfyui/main/config/provisioning/default.sh

# Packages are installed after nodes so we can fix them...

PYTHON_PACKAGES=(
    #"opencv-python==4.7.0.72"
)

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager" # node manager
    "https://github.com/11cafe/comfyui-workspace-manager" # workspace manager (inc. search/download models)
    "https://github.com/crystian/ComfyUI-Crystools" # UI for resource usage monitoring
    "https://github.com/ltdrdata/ComfyUI-Inspire-Pack"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/melMass/comfy_mtb"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    "https://github.com/WASasquatch/was-node-suite-comfyui"
    "https://github.com/daxthin/DZ-FaceDetailer"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/ZHO-ZHO-ZHO/ComfyUI-BRIA_AI-RMBG"
    "https://github.com/florestefano1975/comfyui-portrait-master"
    "https://github.com/shiimizu/ComfyUI-PhotoMaker-Plus"
    "https://github.com/azazeal04/ComfyUI-Styles"
    "https://github.com/jags111/efficiency-nodes-comfyui"
    "https://github.com/bash-j/mikey_nodes"
    "https://github.com/cubiq/ComfyUI_InstantID"
)

CLIP_VISION=(
  "https://huggingface.co/laion/CLIP-ViT-H-14-laion2B-s32B-b79K/resolve/main/open_clip_pytorch_model.bin"
)

CHECKPOINT_MODELS=(
    "https://huggingface.co/SG161222/RealVisXL_V4.0/resolve/main/RealVisXL_V4.0.safetensors"
)

LORA_MODELS=(
    "https://civitai.com/api/download/models/16576"
    "https://civitai.com/api/download/models/126807?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/173623?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/268857?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/162461?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/146364?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/160130?type=Model&format=SafeTensor"
)

VAE_MODELS=(
    "https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors"
    "https://huggingface.co/madebyollin/taesdxl/resolve/main/taesdxl_decoder.safetensors"
    "https://huggingface.co/madebyollin/taesdxl/resolve/main/taesdxl_encoder.safetensors"
)
UPSCALERS=(
    "https://huggingface.co/uwg/upscaler/"
)

SAMS=(
    "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth"
)


### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    sudo apt-get install git-lfs
    DISK_GB_AVAILABLE=$(($(df --output=avail -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_USED=$(($(df --output=used -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_ALLOCATED=$(($DISK_GB_AVAILABLE + $DISK_GB_USED))
    provisioning_print_header
    provisioning_get_upscale_models
    provisioning_get_nodes
    provisioning_install_python_packages
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/ckpt" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/lora" \
        "${LORA_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/controlnet/instantid" \
          "https://huggingface.co/InstantX/InstantID/resolve/main/ControlNetModel/diffusion_pytorch_model.safetensors"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/clip_vision" \
        "${CLIP_VISION[@]}"
    provisioning_get_models \
        "/opt/ComfyUI/models/sams" \
        "${SAMS[@]}"
    provisioning_get_models \
        "/opt/ComfyUI/custom_nodes/ComfyUI-BRIA_AI-RMBG/RMBG-1.4" \
        "https://huggingface.co/briaai/RMBG-1.4/resolve/main/model.pth"
    provisioning_get_models \
        "/opt/ComfyUI/models/photomaker" \
        "https://huggingface.co/TencentARC/PhotoMaker/blob/main/photomaker-v1.bin"
    provisioning_print_end
}

function provisioning_get_upscale_models() {
    for repo in "${UPSCALERS[@]}"; do
        path="/opt/ComfyUI/models/upscale_models"
        printf "Downloading upscale models: %s...\n" "${repo}"
        git clone "${repo}" "${path}" --recursive
    done
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="/opt/ComfyUI/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                    micromamba -n comfyui run ${PIP_INSTALL} -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                micromamba -n comfyui run ${PIP_INSTALL} -r "${requirements}"
            fi
        fi
    done
}

function provisioning_install_python_packages() {
    if [ ${#PYTHON_PACKAGES[@]} -gt 0 ]; then
        micromamba -n comfyui run ${PIP_INSTALL} ${PYTHON_PACKAGES[*]}
    fi
}

function provisioning_get_models() {
    if [[ -z $2 ]]; then return 1; fi
    dir="$1"
    mkdir -p "$dir"
    shift
    if [[ $DISK_GB_ALLOCATED -ge $DISK_GB_REQUIRED ]]; then
        arr=("$@")
    else
        printf "WARNING: Low disk space allocation - Only the first model will be downloaded!\n"
        arr=("$1")
    fi

    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
    if [[ $DISK_GB_ALLOCATED -lt $DISK_GB_REQUIRED ]]; then
        printf "WARNING: Your allocated disk size (%sGB) is below the recommended %sGB - Some models will not be downloaded\n" "$DISK_GB_ALLOCATED" "$DISK_GB_REQUIRED"
    fi
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Web UI will start now\n\n"
}

# Download from $1 URL to $2 file path
function provisioning_download() {
    wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
}

provisioning_start
