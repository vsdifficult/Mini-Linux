
FROM alpine:latest

LABEL maintainer="user@example.com"
LABEL description="Mini-Linux Container for K8S"
LABEL version="1.0"

RUN apk --no-cache add \
    bash \
    curl \
    wget \
    vim \
    htop \
    procps \
    busybox-extras \
    nginx \
    && mkdir -p /run/nginx

COPY nginx.conf /etc/nginx/nginx.conf

COPY index.html /usr/share/nginx/html/index.html

COPY init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 80

CMD ["/init.sh"]