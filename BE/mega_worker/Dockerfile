FROM node:22-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && mkdir -p /data && chown node:node /data
COPY *.mjs ./
USER node
ENV NODE_ENV=production PORT=8080 STUDENTLAB_MEGA_DATA_DIR=/data
EXPOSE 8080
CMD ["node", "server.mjs"]
