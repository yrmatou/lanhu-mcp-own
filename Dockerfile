FROM python:3.10-slim

# 设置工作目录
WORKDIR /app

# 设置构建时代理参数
ARG HTTP_PROXY
ARG HTTPS_PROXY

# 设置环境变量
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV PYTHONUNBUFFERED=1

# 配置国内镜像加速（阿里云）以解决 apt-get update 超时问题，并且替换安全更新源
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
    sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list 2>/dev/null || true
RUN sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
    sed -i 's|security.debian.org/debian-security|mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list 2>/dev/null || true

# 安装系统依赖（临时忽略可能在 docker 内不可达的 proxy 变量）
RUN http_proxy="" https_proxy="" HTTP_PROXY="" HTTPS_PROXY="" apt-get update --fix-missing && apt-get install -y \
    curl \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装Python依赖 (使用阿里云镜像并临时忽略代理变量)
RUN http_proxy="" https_proxy="" HTTP_PROXY="" HTTPS_PROXY="" pip install --no-cache-dir -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/

# 安装Playwright浏览器 (尝试使用官方源直连，因 npmmirror 暂未同步最新版本)
RUN http_proxy="" https_proxy="" HTTP_PROXY="" HTTPS_PROXY="" playwright install chromium
RUN http_proxy="" https_proxy="" HTTP_PROXY="" HTTPS_PROXY="" playwright install-deps chromium

# 复制MCP服务器文件
COPY lanhu_mcp_server.py .

# 创建数据和日志目录
RUN mkdir -p /app/data /app/logs

# 清理代理环境变量
ENV HTTP_PROXY=
ENV HTTPS_PROXY=

# 暴露端口
EXPOSE 8000

# 运行MCP服务器（使用HTTP传输）
CMD ["python", "lanhu_mcp_server.py"]

