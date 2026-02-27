FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

ENV PORT=5050

EXPOSE 5050

CMD ["node", "server.mjs"]
