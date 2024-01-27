# Stage 1: Base
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as base

ARG INSTANTID_COMMIT=691462453d37481e17f5eed552d612e66e18fa84
ARG TORCH_VERSION=2.0.1
ARG XFORMERS_VERSION=0.0.22

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash

# Create workspace working directory
WORKDIR /

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        software-properties-common \
        build-essential \
        python3.10-venv \
        python3-pip \
        python3-tk \
        python3-dev \
        nginx \
        bash \
        dos2unix \
        git \
        git-lfs \
        ncdu \
        net-tools \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        zip \
        unzip \
        htop \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 libtcmalloc-minimal4 \
        apt-transport-https ca-certificates && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set Python
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# Stage 2: Install InstantID and python modules
FROM base as setup

# Create and use the Python venv
RUN python3 -m venv /venv

# Install Torch
RUN source /venv/bin/activate && \
    pip3 install --no-cache-dir torch==${TORCH_VERSION} torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip3 install xformers==${XFORMERS_VERSION} && \
    deactivate

# Clone the git repo of InstantID and set version
WORKDIR /
RUN git clone https://github.com/radames/InstantID.git -b improve-demo-lcm-controlnet && \
    cd /InstantID && \
    git checkout ${INSTANTID_COMMIT}


# Install the dependencies for InstantID
WORKDIR /InstantID/gradio_demo
COPY instantid/requirements.txt ./
RUN source /venv/bin/activate && \
    pip3 install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu118 && \
    deactivate

COPY instantid/* ./

# Symlink required files
RUN ln -s ../pipeline_stable_diffusion_xl_instantid.py pipeline_stable_diffusion_xl_instantid.py && \
    ln -s ../ip_adapter ip_adapter && \
    ln -s ../examples examples


RUN git lfs install

# Install Jupyter
RUN pip3 install -U --no-cache-dir jupyterlab \
        jupyterlab_widgets \
        ipykernel \
        ipywidgets \
        gdown

RUN source /venv/bin/activate && \
    pip3 install controlnet-aux && \
    deactivate


# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Install croc
RUN curl https://getcroc.schollz.com | bash

# Install speedtest CLI
RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash && \
    apt install speedtest

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/502.html /usr/share/nginx/html/502.html

# Set up the container startup script
WORKDIR /

# Copy the scripts
COPY --chmod=755 scripts/* ./

# Start the container
ENV TEMPLATE_VERSION=1.0.0
SHELL ["/bin/bash", "--login", "-c"]
ENTRYPOINT [ "/start.sh" ]
