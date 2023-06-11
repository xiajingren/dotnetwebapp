#!/bin/bash

## 免登录
## ssh-keygen
## ssh-copy-id root@82.157.145.132

## 服务器安装环境 https://learn.microsoft.com/zh-cn/dotnet/core/install/linux-centos
## sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
## sudo yum install aspnetcore-runtime-7.0

## 变量
app_name="WebApplication1"
app_dll="WebApplication1.dll" # 应用程序的主要 DLL 文件名
app_port="8001"
publish_folder="publish"
remote_user="root"
remote_host="82.157.145.132"
remote_destination="/home/dotnetwebapp"

## 还原项目
dotnet restore
## 发布项目
dotnet publish -c Release -o $publish_folder

## 压缩
tar -czvf $publish_folder.tar.gz $publish_folder

## 准备服务器
ssh $remote_user@$remote_host <<mkdir
    mkdir -p $remote_destination
mkdir

## 拷贝到服务器
scp $publish_folder.tar.gz $remote_user@$remote_host:$remote_destination

## 部署
ssh $remote_user@$remote_host <<deploy
    # 停止正在运行的应用程序服务
    sudo systemctl stop $app_name.service

    cd $remote_destination
    # mv $remote_destination/$publish_folder $remote_destination/$publish_folder-backup-$(date +'%Y%m%d%H%M%S') #备份
    tar -xzvf $publish_folder.tar.gz

    cd $publish_folder
    # sed -i "s|CONNECTION_STRING_PLACEHOLDER|$db_connection_string|g" "appsettings.json" #替换数据库连接字符串

    # 更新应用程序的 Systemd 服务文件
    echo '[Unit]
        Description=ASP.NET Core App - $app_name

        [Service]
        WorkingDirectory=$remote_destination/$publish_folder
        ExecStart=/usr/bin/dotnet $app_dll --Urls=http://*:$app_port  > $remote_destination/start.log 2>&1 &
        Restart=always
        RestartSec=10
        SyslogIdentifier=$app_name
        User=$remote_user
        Environment=ASPNETCORE_ENVIRONMENT=Production
        Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

        [Install]
        WantedBy=multi-user.target' | sudo tee /etc/systemd/system/$app_name.service > /dev/null

    # 重新加载 Systemd 服务配置
    sudo systemctl daemon-reload

    # 启动应用程序服务
    sudo systemctl enable $app_name.service
    sudo systemctl start $app_name.service

    # 检查服务状态
    sudo systemctl status $app_name.service

    echo "部署完成。。。"
deploy

## 清理
rm -rf $publish_folder
rm -f $publish_folder.tar.gz
