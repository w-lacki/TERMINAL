FROM node:alpine AS build
WORKDIR /src
ARG VITE_HYPERDX_API_KEY
ARG VITE_HYPERDX_URL
ENV VITE_HYPERDX_API_KEY=$VITE_HYPERDX_API_KEY
ENV VITE_HYPERDX_URL=$VITE_HYPERDX_URL
COPY package*.json .
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /src/dist /usr/share/nginx/html
COPY ./nginx.conf etc/nginx/conf.d/default.conf
EXPOSE 5173
CMD [ "nginx", "-g", "daemon off;"]
