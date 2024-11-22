FROM nvcr.io/nvidia/l4t-jetpack:r35.4.1 as build-cuda-plugin
LABEL maintainer="Jadeiin <92222981+Jadeiin@users.noreply.github.com>"

ARG CUDA_PLUGIN_VERSION=6.22.0-mo1
RUN set -xe; \
  apt-get update; \
  apt-get install -y cmake automake libtool autoconf; \
  rm -rf /var/lib/apt/lists/*; \
  apt-get clean; \
  wget https://github.com/MoneroOcean/xmrig-cuda/archive/refs/tags/v${CUDA_PLUGIN_VERSION}.tar.gz; \
  tar xf v${CUDA_PLUGIN_VERSION}.tar.gz; \
  mv xmrig-cuda-${CUDA_PLUGIN_VERSION} xmrig-cuda; \
  cd xmrig-cuda; \
  mkdir build; \
  cd build; \
  cmake .. -DCUDA_LIB=/usr/lib/aarch64-linux-gnu/libcuda.so -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda -DCUDA_ARCH="87"; \
  make -j $(nproc);


FROM nvcr.io/nvidia/l4t-jetpack:r35.4.1 as build-runner
ARG XMRIG_VERSION=6.22.0-mo3
LABEL maintainer="Jadeiin <92222981+Jadeiin@users.noreply.github.com>"

RUN set -xe; \
  apt-get update; \
  apt-get install -y cmake automake libtool autoconf; \
  rm -rf /var/lib/apt/lists/*; \
  apt-get clean; \
  wget https://github.com/MoneroOcean/xmrig/archive/refs/tags/v${XMRIG_VERSION}.tar.gz; \
  tar xf v${XMRIG_VERSION}.tar.gz; \
  mv xmrig-${XMRIG_VERSION} /xmrig; \
  cd /xmrig; \
  mkdir build; \
  cd scripts; \
  ./build_deps.sh; \
  cd ../build; \
  cmake .. -DXMRIG_DEPS=scripts/deps; \
  make -j $(nproc);

RUN set -xe; \
  cd /xmrig; \
  cp build/xmrig /xmrig


FROM nvcr.io/nvidia/l4t-jetpack:r35.4.1 as runner
LABEL maintainer="Jadeiin <92222981+Jadeiin@users.noreply.github.com>"
LABEL org.opencontainers.image.source="https://github.com/Jadeiin/docker-xmrig"
LABEL org.opencontainers.image.description="XMRig miner with CUDA support on Docker, Podman, Kubernetes..." 
LABEL org.opencontainers.image.licenses="MIT"
RUN set -xe; \
  mkdir /xmrig; \
  apt-get update; \
  apt-get -y install jq; \
  rm -rf /var/lib/apt/lists/*; \
  apt-get clean;
COPY --from=build-runner /xmrig/xmrig /xmrig/xmrig
COPY --from=build-runner /xmrig/src/config.json /xmrig/config.json
COPY --from=build-cuda-plugin /xmrig-cuda/build/libxmrig-cuda.so /usr/local/lib/


ENV POOL_USER="" \
  POOL_PASS="" \
  POOL_URL="xmr.example.org:8080" \
  DONATE_LEVEL=5 \
  PRIORITY=0 \
  THREADS=0 \
  PATH="/xmrig:${PATH}" \
  CUDA=true \
  CUDA_BF="" \
  ALGO="" \
  COIN="" \
  THREAD_DIVISOR="2"

WORKDIR /xmrig
COPY entrypoint.sh /entrypoint.sh
WORKDIR /tmp
EXPOSE 3000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["xmrig"]
