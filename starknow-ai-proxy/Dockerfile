# 星知 AI 代理服务（不修改 server.js，仅容器化）
FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY server.js ./

EXPOSE 3001

ENV NODE_ENV=production
CMD ["node", "server.js"]
