FROM node:16 as builder

WORKDIR /app
COPY package*.json ./
RUN npm install

FROM node:16-slim

RUN apt-get update && apt-get install -y \
    python3 \
    build-essential \
    libssl-dev \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .

RUN mkdir -p /tmp/uploads

EXPOSE 80
CMD ["node", "app.js"]
