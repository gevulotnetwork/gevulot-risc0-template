# Stage 1: Ubuntu 20.04 + CUDA 12.2.2 dev kit + Rust + RISC0
FROM docker.io/nvidia/cuda:12.2.2-devel-ubuntu20.04 AS base
# NOTE: CUDA version taken from RISC0 CI scripts.

# Disable apt warnings
ENV DEBIAN_FRONTEND=noninteractive

# Install apt dependencies
RUN apt-get update
RUN apt-get -y install curl build-essential libssl-dev git pkg-config

# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="$PATH:/root/.cargo/bin"

# Install RISC0
RUN curl -L https://risczero.com/install | bash
ENV PATH="$PATH:/root/.risc0/bin"
RUN rzup install

# Stage 2: build source code
FROM base as builder

# Create project directory
RUN mkdir -p /risc0-template
WORKDIR /risc0-template

# Copy all sources
ADD . .

# Build sources
ENV RUSTFLAGS="-C target-cpu=native"
# Match this with desired NVIDIA GPU
ENV NVCC_APPEND_FLAGS="--gpu-architecture=compute_89 --gpu-code=compute_89,sm_89 --generate-code arch=compute_89,code=sm_89"
RUN cargo build --features cuda --release

# Copy executable
RUN cp /template/target/release/host /host

# Stage 3: minimal runtime environment
FROM docker.io/nvidia/cuda:12.2.2-base-ubuntu20.04

# Copy main executable
COPY --from=builder /host /host

# Set up entrypoint
ENTRYPOINT ["/host"]
