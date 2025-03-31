# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
RUN apk add --no-cache python3 py3-pip make g++
COPY package*.json ./
RUN npm ci --include=dev
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine
WORKDIR /app
ENV NODE_ENV=production
# Añadimos Python y herramientas de compilación también en producción
RUN apk add --no-cache python3 py3-pip make g++

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/Electron ./Electron
COPY --from=builder /app/Assets ./Assets

RUN npm ci --omit=dev && \
    npm cache clean --force

EXPOSE 3000
CMD ["npm", "start"]
