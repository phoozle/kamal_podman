FROM nginx:latest

RUN echo "Hello from Kamal Podman Test App!" > /usr/share/nginx/html/index.html

RUN echo '{"version": "'$(date +%s)'", "host": "'$(hostname)'"}' > /usr/share/nginx/html/version

# Add health check endpoint
RUN echo "OK" > /usr/share/nginx/html/up

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
