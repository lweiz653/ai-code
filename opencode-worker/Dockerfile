FROM node:22-bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    ca-certificates \
    bash \
    openssh-client \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai

RUN mkdir -p /runner /workspace /logs /artifacts

WORKDIR /workspace

COPY run-task.sh /runner/run-task.sh
RUN chmod +x /runner/run-task.sh

ENTRYPOINT ["/runner/run-task.sh"]
