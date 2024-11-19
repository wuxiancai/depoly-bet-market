#!/bin/bash

# 配置变量
PROJECT_DIR=~/betmarket
TSX_FILE=BETMARKET.TSX
DOMAIN_NAME=your-domain.com

echo "=== 部署脚本开始 ==="

# 更新系统
echo "1. 更新系统..."
sudo apt update && sudo apt upgrade -y

# 安装 Node.js 和 npm
echo "2. 安装 Node.js 和 npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 检查 Node.js 和 npm
echo "检查 Node.js 和 npm 版本..."
node -v
npm -v

# 创建项目目录
echo "3. 创建项目目录..."
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# 初始化 Node.js 项目
echo "4. 初始化 Node.js 项目..."
npm init -y

# 安装 Vite 和 React 相关依赖
echo "5. 安装 Vite 和 React 相关依赖..."
npm install react react-dom vite

# 初始化 TypeScript 配置
echo "6. 初始化 TypeScript 配置..."
npx tsc --init

# 上传并配置 TSX 文件
echo "7. 配置 TSX 文件..."
if [ ! -f "$TSX_FILE" ]; then
    echo "❌ 未找到 $TSX_FILE 文件，请将文件上传到 $PROJECT_DIR 后重新运行脚本。"
    exit 1
fi
mkdir -p src
mv $TSX_FILE src/BetMarket.tsx

# 修改 package.json 脚本
echo "8. 配置 package.json 脚本..."
jq '.scripts += {"dev": "vite", "build": "vite build", "start": "vite preview"}' package.json > tmp.json && mv tmp.json package.json

# 构建生产版本
echo "9. 构建生产版本..."
npm run build

# 启动生产预览
echo "10. 启动生产服务器..."
npm install -g serve
serve -s dist &

# 安装并配置 Nginx
echo "11. 安装并配置 Nginx..."
sudo apt install -y nginx

# 配置 Nginx 文件
echo "配置 Nginx..."
sudo bash -c "cat > /etc/nginx/sites-available/betmarket" <<EOL
server {
    listen 80;

    server_name $DOMAIN_NAME;

    location / {
        root $PROJECT_DIR/dist;
        index index.html;
    }
}
EOL

# 启用 Nginx 配置
echo "启用 Nginx 配置..."
sudo ln -s /etc/nginx/sites-available/betmarket /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# 检查服务状态
echo "12. 检查服务状态..."
sudo systemctl status nginx

echo "=== 部署完成 ==="
echo "网站已上线，访问 http://$DOMAIN_NAME 测试。"
