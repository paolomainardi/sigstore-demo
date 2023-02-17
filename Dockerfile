FROM nginx:alpine
RUN apk add --no-cache curl

COPY src  /usr/share/nginx/html

