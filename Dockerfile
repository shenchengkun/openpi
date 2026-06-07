# syntax=docker/dockerfile:1.7

FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-c"]
WORKDIR /workspace

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y \
    locales \
    software-properties-common \
    curl \
    ca-certificates \
    git \
    wget \
    build-essential \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/var/cache/apt \
    add-apt-repository universe -y \
    && apt-get update \
    && export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F'"' '{print $4}') \
    && curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb" \
    && dpkg -i /tmp/ros2-apt-source.deb \
    && rm /tmp/ros2-apt-source.deb \
    && apt-get update \
    && apt-get install -y \
       ros-jazzy-ros-base \
       ros-dev-tools \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

RUN python -m pip install --upgrade pip setuptools wheel

# Install uv
RUN python -m pip install uv

# Copy only dependency metadata first for better cache reuse
WORKDIR /tmp/openpi
COPY pyproject.toml README.md ./

# Preload dependency solver/download cache
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-install-project || true

WORKDIR /workspace/openpi
COPY . /workspace/openpi

# Full environment install using repo-native resolver
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc

CMD ["/bin/bash"]