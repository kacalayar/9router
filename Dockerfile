# syntax=docker/dockerfile:1.7
ARG NODE_IMAGE=node:22-alpine
FROM ${NODE_IMAGE} AS base
WORKDIR /app

FROM base AS builder

# Install build tools
RUN apk --no-cache upgrade && apk --no-cache add python3 make g++ linux-headers

# Copy package.json dan install dependencies
COPY package.json ./
RUN npm install --include=dev

# Copy semua source code
COPY . ./
ENV NEXT_TELEMETRY_DISABLED=1

# Build Next.js
RUN npx next build --webpack

FROM ${NODE_IMAGE} AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=20128
ENV HOSTNAME=0.0.0.0
ENV NEXT_TELEMETRY_DISABLED=1
ENV DATA_DIR=/app/data

# Copy hasil build dari builder
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/open-sse ./open-sse
COPY --from=builder /app/src/mitm ./src/mitm
COPY --from=builder /app/node_modules/node-forge ./node_modules/node-forge
COPY --from=builder /app/node_modules/next ./node_modules/next

EXPOSE 20128
CMD ["node", "server.js"]
