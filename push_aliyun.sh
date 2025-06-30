#!/bin/bash
PUSH_IMAGE=$1
USER_NAME=$2
USER_PWD=$3

echo "$USER_NAME"

echo $USER_PWD | docker login --username=$USER_NAME --password-stdin registry.cn-hongkong.aliyuncs.com
if [ $? -ne 0 ]; then
  echo "登录失败，请检查用户名或密码。"
  exit 1
fi

ALIYUN_IMAGE="registry.cn-hongkong.aliyuncs.com/booster/sync:$PUSH_IMAGE"
LOCAL_IMAGE="sync:$PUSH_IMAGE"
docker build -f Dockerfile -t sync:$PUSH_IMAGE .

if docker image inspect $LOCAL_IMAGE > /dev/null 2>&1; then
    echo "镜像存在，正在重新标记..."
    # 给镜像打上新的标签
    docker tag $LOCAL_IMAGE $ALIYUN_IMAGE
    # 推送镜像到阿里云
    echo "正在推送镜像 $ALIYUN_IMAGE 到阿里云..."
    docker push $ALIYUN_IMAGE
    echo "镜像 $LOCAL_IMAGE 已成功上传到 $ALIYUN_IMAGE"
else
    echo "错误：镜像 $LOCAL_IMAGE 不存在！"
fi
