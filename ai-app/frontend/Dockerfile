FROM node:16 as build

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

ENV VUE_APP_API_URL=http://ai-backend:92

RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
