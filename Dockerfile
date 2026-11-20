FROM nginx:alpine
LABEL org.opencontainers.image.title="developer-workstation-web"
ENV APP_ENV=practice
COPY site/ /usr/share/nginx/html/
