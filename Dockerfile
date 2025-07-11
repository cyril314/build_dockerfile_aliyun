# 构建阶段：使用 Go 1.15 编译 NPS 和 NPC
FROM golang:1.15 AS builder

ARG GOPROXY=https://goproxy.cn,direct
WORKDIR /build

# 克隆 NPS 源码
RUN git clone https://github.com/ehang-io/nps.git . \
    && go mod download

# 编译服务端 (nps)
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s -extldflags -static" -o nps ./cmd/nps

# 编译客户端 (npc)
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s -extldflags -static" -o npc ./cmd/npc

# 最终阶段：基于 Alpine 的轻量级镜像
FROM alpine:latest

# 从 builder 复制二进制文件
COPY --from=builder /build/nps /usr/local/bin/
COPY --from=builder /build/npc /usr/local/bin/
COPY --from=builder /build/web /web
COPY --from=builder /build/conf /conf_default

# 创建配置文件目录
VOLUME /conf

# 添加启动脚本
RUN echo -e '#!/bin/sh\n\
if [ "$MODE" = "server" ]; then\n\
    if [ ! "$(ls -A /conf)" ]; then\n\
        echo 'Initializing /conf files...';\n\
        rm -f /conf_default/npc.conf\n\
        cp -r /conf_default/* /conf/;\n\
    fi;\n\
    exec nps\n\
else\n\
    if [ ! "$(ls -A /conf)" ]; then\n\
        echo 'Initializing /conf/npc.conf files...';\n\
        cp -r /conf_default/npc.conf /conf/;\n\
    fi;\n\
    exec npc\n\
fi' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
