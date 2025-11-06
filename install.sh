#!/bin/bash

# 设置变量
setup_variables() {
    APP_NAME=nginx
    SNI=www.bing.com
    
    # 检查必要的环境变量
    if [ -z "$SERVER_PORT" ]; then
        echo "错误: SERVER_PORT 环境变量未设置"
        exit 1
    fi
    
    if [ -z "$SERVER_IP" ]; then
        echo "错误: SERVER_IP 环境变量未设置"
        exit 1
    fi
    
    # 询问用户输入密码
    echo "请输入密码 (留空将使用随机生成的密码):"
    read -s USER_PW
    
    # 检查用户是否输入了密码
    if [ -z "$USER_PW" ]; then
        # 生成随机密码
        PW=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
        echo "已生成随机密码: $PW"
    else
        PW=$USER_PW
        echo "已使用您输入的密码"
    fi
}

# 下载应用程序
download_application() {
    echo "下载应用程序..."
    wget -O $APP_NAME 'https://github.com/apernet/hysteria/releases/download/app%2Fv2.6.5/hysteria-linux-amd64'
    if [ $? -ne 0 ]; then
        echo "错误: 下载应用程序失败"
        exit 1
    fi
    chmod +x $APP_NAME
}

gen_cert() {
cat > cert.key <<EOF
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgaMdU/fbzIEud0KUd
qzEN43b5XBXQAnZV4q+Ci15umpuhRANCAATMGfOdu96xzE4YmWE6bKlaVc6H3rMP
XdNFhuspRZF4bvXBjioNmgo/vJIQ8RFjfb+R2+Zt9zW3ZRKl7PRUPFYO
-----END PRIVATE KEY-----
EOF
cat > cert.pem <<EOF
-----BEGIN CERTIFICATE-----
MIIBfTCCASOgAwIBAgIUY6QFzCwGws3o2DR925qzz8yjL8QwCgYIKoZIzj0EAwIw
FDESMBAGA1UEAwwJbG9jYWxob3N0MB4XDTI1MDgyNDAyMDczOFoXDTM1MDgyMjAy
MDczOFowFDESMBAGA1UEAwwJbG9jYWxob3N0MFkwEwYHKoZIzj0CAQYIKoZIzj0D
AQcDQgAEzBnznbvescxOGJlhOmypWlXOh96zD13TRYbrKUWReG71wY4qDZoKP7yS
EPERY32/kdvmbfc1t2USpez0VDxWDqNTMFEwHQYDVR0OBBYEFFHn4FkWL3+zmi0y
C7FFve6tQYrCMB8GA1UdIwQYMBaAFFHn4FkWL3+zmi0yC7FFve6tQYrCMA8GA1Ud
EwEB/wQFMAMBAf8wCgYIKoZIzj0EAwIDSAAwRQIhAJEJX+Fa4BCr62GFdLOa4fJt
bLRx1xXYQGmQWeL/zhm+AiBkikMym7Mn44gTnVEDkj7uFnGiMiIUKdyJKUYQQbWi
6g==
-----END CERTIFICATE-----
EOF
}

# 创建配置文件
create_config_file() {
    echo "创建配置文件..."
    cat > config.yaml <<EOF
listen: :${SERVER_PORT}

auth:
  type: password
  password: $PW

tls:
  cert: ./cert.pem
  key: ./cert.key
EOF
    echo "配置文件创建完成"
}

# 生成连接信息
generate_connection_info() {
    echo "生成连接信息..."
    echo "hy2://${PW}@${SERVER_IP}:${SERVER_PORT}?sni=${SNI}&insecure=1&alpn=h3#lunes_hy2" > ./hy2.txt
    echo "连接信息:"
    cat ./hy2.txt
}

# 创建启动脚本
create_startup_script() {
    cat > start.sh <<EOF
#!/bin/bash
nohup ./$APP_NAME server -c config.yaml &
EOF
    chmod +x start.sh
}

# 启动应用程序
start_application() {
    sh ./start.sh
    if [ $? -ne 0 ]; then
        echo "错误: 启动应用程序失败"
        exit 1
    fi
}


# 主函数
main() {
    echo "开始安装 Hysteria 2..."
    mkdir -p app
    cd app
    
    setup_variables
    gen_cert
    download_application
    create_config_file
    generate_connection_info
    create_startup_script
    start_application

    cd -
}

# 执行主函数
main
