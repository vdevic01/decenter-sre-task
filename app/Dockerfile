# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

# Install dependencies (including dev dependencies for build)
RUN npm ci

COPY . .

RUN npm run build

# Production stage
FROM node:20-alpine AS production

USER node
WORKDIR /app

COPY package*.json ./

# Set NODE_ENV before install so npm automatically omits devDependencies
ENV NODE_ENV=production
ENV HOST=0.0.0.0
RUN npm ci

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:${PORT:-3000}/health || exit 1

CMD ["node", "dist/main.js"]
