FROM ubuntu:22.04 AS base

RUN apt update \
  && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
  git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget curl \
  python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
  make gcc libsdl2-dev libmagic1 srecord \
  tzdata dnsutils openssh-client \
  clang-format clang-tidy cppcheck

# Install multi-lib gcc (x86 only)
RUN if [ "$(uname -m)" = "x86_64" ]; then \
  apt update \
  && DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y \
    gcc-multilib \
    g++-multilib \
  ; fi

RUN pip install west pyelftools pre-commit

# Install Node.js and Claude Code CLI
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
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
USER user
RUN mkdir -p /home/user/zephyrproject /home/user/zephyrproject/workspace

# Initialize and update the shared Zephyr project
WORKDIR /home/user/zephyrproject
RUN west init -l --mf /opt/zephyr-sdk-$ZSDK_VERSION/west.yml test && west update

# Set up environment variables for the shared project
RUN pip3 install -r /home/user/zephyrproject/zephyr/scripts/requirements.txt

# Add devcontainer feature files for use with VS Code devcontainers
ADD zephyr-dev-features /home/user/zephyrproject/workspace/.devcontainer/features/

FROM src_stage AS final
USER user
RUN git clone --branch v3.6.0 --depth 1 \
    https://github.com/zephyrproject-rtos/example-application.git
ADD --chown=user:user example-application.yml /home/user/zephyrproject/example-application/west.yml
ADD --chown=user:user west_config /home/user/zephyrproject/.west/config
ADD --chown=user:user west.yml /home/user/zephyrproject/west.yml
WORKDIR /home/user/zephyrproject/example-application

RUN echo "export PATH=/opt/JLink:\$PATH" >> /home/user/.bashrc && \
    echo "export ZEPHYR_BASE=/home/user/zephyrproject/zephyr" >> /home/user/.bashrc && \
    echo "export ZEPHYR_PROJECT_ROOT=/home/user/zephyrproject" >> /home/user/.bashrc
# Default command
RUN west update
CMD ["/bin/bash"]

