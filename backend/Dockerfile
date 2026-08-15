# ---- Build ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci
COPY . .
RUN npm run prisma:generate && npm run build

# ---- Runtime ----
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci --omit=dev && npm run prisma:generate
COPY --from=build /app/dist ./dist
EXPOSE 3000
# Applique les migrations puis démarre.
CMD ["sh", "-c", "npm run prisma:deploy && node dist/main"]
