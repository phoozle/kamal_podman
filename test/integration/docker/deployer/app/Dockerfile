FROM registry:5000/nginx:latest

ARG COMMIT_SHA
RUN echo $COMMIT_SHA > /usr/share/nginx/html/version && \
    echo "Up!" > /usr/share/nginx/html/up

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
