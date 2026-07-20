# --- Build stage ---
FROM node:20-alpine AS build
WORKDIR /app
COPY app/src/package.json ./
RUN npm install --omit=dev
COPY app/src/ ./

# --- Runtime stage ---
# Only the installed dependencies + app code get copied forward — no build
# tools, no npm cache, no dev dependencies in the final image.
FROM node:20-alpine AS runtime
WORKDIR /app

# Force latest patched OS packages (e.g. openssl) even if the base image tag
# hasn't been rebuilt upstream yet with the fix. Caught via ECR scan-on-push.
RUN apk update && apk upgrade --no-cache

# Run as a non-root user — never run containers as root in production
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=build /app ./
USER appuser

ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://localhost:3000/health || exit 1

CMD ["node", "index.js"]
