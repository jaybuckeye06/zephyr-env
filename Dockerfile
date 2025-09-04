FROM ubuntu:22.04 AS base

RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt update \
  && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
  git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget curl \
  python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
  make gcc libsdl2-dev libmagic1 srecord \
  tzdata dnsutils openssh-client \
  clang-format clang-tidy cppcheck

# Install multi-lib gcc (x86 only)
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  if [ "$(uname -m)" = "x86_64" ]; then \
  apt update \
  && DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y \
    gcc-multilib \
    g++-multilib \
  ; fi

RUN --mount=type=cache,target=/root/.cache/pip \
  pip install west pyelftools pre-commit

# Install Node.js and Claude Code CLI
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  --mount=type=cache,target=/root/.npm \
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs \
  && npm install -g @anthropic-ai/claude-code

FROM base AS sdk_stage
ARG ZSDK_VERSION=0.16.9
ENV ZSDK_VERSION=$ZSDK_VERSION

COPY ./extra/debugger_arm64.tgz /extra/
COPY ./extra/debugger_x86_64.tgz /extra/

RUN if [ "$(uname -m)" = "x86_64" ]; then \
	wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$ZSDK_VERSION/zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz \
  && tar -xf zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz -C /opt/ \
  && rm zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz \
  && cd /opt/zephyr-sdk-$ZSDK_VERSION \
  && mkdir -p /opt/JLink \
  && tar --strip-components=1 -xf /extra/debugger_x86_64.tgz -C /opt/JLink \
  ; fi

RUN if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then \
	wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$ZSDK_VERSION/zephyr-sdk-${ZSDK_VERSION}_linux-aarch64_minimal.tar.xz \
  && tar -xf zephyr-sdk-${ZSDK_VERSION}_linux-aarch64_minimal.tar.xz -C /opt/ \
  && rm zephyr-sdk-${ZSDK_VERSION}_linux-aarch64_minimal.tar.xz \
  && cd /opt/zephyr-sdk-$ZSDK_VERSION \
  && mkdir -p /opt/JLink \
  && tar --strip-components=1 -xf /extra/debugger_arm64.tgz -C /opt/JLink \
  ; fi

RUN ln -s /opt/zephyr-sdk-$ZSDK_VERSION /opt/zephyr-sdk

RUN rm -rf /extra

ADD sdk_toolchains /opt/zephyr-sdk-$ZSDK_VERSION/

RUN cd /opt/zephyr-sdk-$ZSDK_VERSION && yes | ./setup.sh

FROM sdk_stage AS src_stage
ADD west.yml /opt/zephyr-sdk-$ZSDK_VERSION/

# Create non-root user
RUN useradd -m -s /bin/bash user

# Create a shared Zephyr project directory that can be reused
RUN mkdir -p /home/user/zephyr-project /zephyrproject /zephyrproject/workspace
RUN chown -R user:user /home/user/zephyr-project /zephyrproject

# Initialize and update the shared Zephyr project
USER user
WORKDIR /home/user/zephyr-project
RUN --mount=type=cache,target=/home/user/.cache/pip,uid=1000,gid=1000 \
    cp /opt/zephyr-sdk-$ZSDK_VERSION/west.yml . && \
    west init -l . && west update

# Create symlink so /opt/zephyr-project points to user's directory
USER root
RUN ln -sf /home/user/zephyr-project /opt/zephyr-project
# Set up environment variables for the shared project
USER user
RUN --mount=type=cache,target=/home/user/.cache/pip,uid=1000,gid=1000 \
    pip3 install -r /home/user/zephyr-project/zephyr/scripts/requirements.txt

USER root
RUN echo "export ZEPHYR_BASE=/opt/zephyr-project/zephyr" >> /etc/environment && \
    echo "export ZEPHYR_PROJECT_ROOT=/opt/zephyr-project" >> /etc/environment

FROM src_stage AS final
RUN git clone --branch v3.6.0 --depth 1 \
    https://github.com/zephyrproject-rtos/example-application.git
USER root
ADD example-application.yml /zephyrproject/example-application/west.yml
ADD west_config /zephyrproject/.west/config
ADD west.yml /zephyrproject/west.yml
RUN chown user:user /zephyrproject/west.yml \
    /zephyrproject/example-application/west.yml \
    /zephyrproject/.west/config
USER user
WORKDIR /zephyrproject/example-application

RUN echo "export PATH=/opt/JLink:\$PATH" >> /home/user/.bashrc && \
    echo "export ZEPHYR_BASE=/opt/zephyr-project/zephyr" >> /home/user/.bashrc && \
    echo "export ZEPHYR_PROJECT_ROOT=/opt/zephyr-project" >> /home/user/.bashrc
# Default command
CMD ["/bin/bash"]

