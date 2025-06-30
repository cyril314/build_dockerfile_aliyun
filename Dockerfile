# 第一阶段：构建nps服务端
FROM golang:1.15 as nps-builder
ARG GOPROXY=direct
WORKDIR /go/src/ehang.io/
RUN git clone https://github.com/ehang-io/nps.git && cd nps && pwd && ls
RUN go get -d -v ./... 
RUN CGO_ENABLED=0 go build -ldflags="-w -s -extldflags -static" ./cmd/nps/nps.go

# 第二阶段：构建npc客户端
FROM golang:1.15 as npc-builder
ARG GOPROXY=direct
WORKDIR /go/src/ehang.io/
RUN git clone https://github.com/ehang-io/nps.git && cd nps && pwd && ls
RUN go get -d -v ./... 
RUN CGO_ENABLED=0 go build -ldflags="-w -s -extldflags -static" ./cmd/npc/npc.go

# 最终阶段：合并并添加启动脚本
FROM alpine
# 从nps-builder复制nps和web文件
COPY --from=nps-builder /go/src/ehang.io/nps/nps /usr/local/bin/nps
COPY --from=nps-builder /go/src/ehang.io/nps/web /web
# 从npc-builder复制npc
COPY --from=npc-builder /go/src/ehang.io/nps/npc /usr/local/bin/npc

# 添加启动脚本
RUN echo -e '#!/bin/sh\nif [ "$MODE" = "server" ]; then\n  exec nps\nelif [ "$MODE" = "client" ]; then\n  exec npc\nelse\n  echo "Please set MODE=server or MODE=client"\n  exit 1\nfi' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

# 创建配置文件目录
VOLUME /conf

ENTRYPOINT ["/entrypoint.sh"]
