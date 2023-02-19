FROM nginx:alpine

RUN apk add --no-cache curl nodejs npm && \
    npm install -g firebase-tools

COPY src  /usr/share/nginx/html

