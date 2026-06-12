FROM node:22-alpine

WORKDIR /app

# Install backend production dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Install admin panel build dependencies and build it
COPY admin-panel/package*.json ./admin-panel/
RUN npm --prefix admin-panel ci

COPY . .

RUN npm --prefix admin-panel run build

# Remove admin-panel node_modules — not needed at runtime
RUN rm -rf admin-panel/node_modules

EXPOSE 3000

CMD ["node", "server.js"]
