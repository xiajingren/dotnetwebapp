#!/bin/bash

## 变量
app_name="WebApplication1"
app_dll="WebApplication1.dll" # 应用程序的主要 DLL 文件名
app_port="8001"
publish_folder="publish"
remote_user="root"
remote_host="82.157.145.132"
remote_destination="/home/dotnetwebapp"

start() {
    ssh $remote_user@$remote_host "sudo systemctl enable $app_name.service \
        && sudo systemctl start $app_name.service"
}

stop() {
    ssh $remote_user@$remote_host \
        sudo systemctl stop $app_name.service
}

# 获取第一个参数
action=$1

# 根据参数执行对应的方法
case "$action" in
"start")
    echo "启动服务..."
    start
    ;;
"stop")
    echo "停止服务..."
    stop
    ;;
*)
    echo "无效的参数：$action"
    ;;
esac
