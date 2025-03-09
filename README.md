# Minimal Zephyr Development Environment

This repository contains a Docker-based development environment for Zephyr RTOS, specifically optimized for ARM and ESP32 development. The environment is designed to be minimal, including only the necessary components and toolchains.

## Features

- Minimal Zephyr RTOS environment with only required modules
- Optimized SDK installation with support for:
  - ARM toolchain
  - ESP32 toolchain
- Reduced image size by excluding unnecessary hardware HALs and software packages

## Prerequisites

- Docker installed on your system
- Git

## Building the Docker Image

```bash
docker build -t zephyr-env .
```

## Usage

Run the container:
```bash
docker run -it --rm zephyr-env
```

Mount your project directory:
```bash
docker run -it --rm -v $(pwd):/workdir zephyr-env
```

## 
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t jaybuckeye06/zephyr-env:v3.6.0 .
```

## Customization

The environment can be customized by:
1. Modifying the west manifest to include additional modules
2. Adding more toolchains to the SDK installation
3. Adjusting the Docker build process in the Dockerfile

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details. 