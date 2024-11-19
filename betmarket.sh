#!/bin/bash

# 部署配置
PROJECT_DIR=~/bet-market
TSX_FILE=BET-MARKET.TSX
DOMAIN_NAME=your-domain.com

echo "=== 自动化部署脚本开始 ==="

# 更新和升级系统
echo "1. 更新和升级系统..."
sudo apt update && sudo apt upgrade -y

# 安装 Node.js 和 npm
echo "2. 安装 Node.js 和 npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 检查 Node.js 和 npm 是否安装成功
echo "检查 Node.js 和 npm 版本..."
node -v
npm -v

# 创建项目目录
echo "3. 创建项目目录: $PROJECT_DIR..."
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# 初始化 Node.js 项目
echo "4. 初始化项目..."
npm init -y

# 安装依赖
echo "5. 安装 React、TypeScript 和 Vite..."
npm install react react-dom typescript vite

# 初始化 TypeScript 配置
echo "6. 初始化 TypeScript 配置..."
npx tsc --init

# 上传 TSX 文件（假设文件已上传）
if [ -f "$TSX_FILE" ]; then
    echo "7. 上传 $TSX_FILE 到项目目录..."
    mv $TSX_FILE src/bet-market.tsx
else
    echo "❌ 未找到 $TSX_FILE 文件，请先上传文件到当前目录后重试。"
    exit 1
fi

# 修改 package.json
echo "8. 修改 package.json 脚本..."
jq '.scripts += {"dev": "vite", "build": "vite build", "start": "vite preview"}' package.json > tmp.json && mv tmp.json package.json

# 启动开发服务器（可选）
echo "9. 启动开发服务器测试..."
npm run dev &

# 构建生产版本
echo "10. 构建生产版本..."
npm run build

# 启动生产预览
echo "11. 启动生产服务器..."
npm run start &

# 安装并配置 Nginx（如果需要）
echo "12. 安装并配置 Nginx..."
sudo apt install nginx -y

# 配置 Nginx
echo "配置 Nginx 文件..."
sudo bash -c "cat > /etc/nginx/sites-available/default" <<EOL
server {
    listen 80;

    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:4173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# 重启 Nginx
echo "重启 Nginx..."
sudo systemctl restart nginx

# 完成
echo "=== 部署完成 ==="
echo "访问 http://$DOMAIN_NAME 查看项目。"
