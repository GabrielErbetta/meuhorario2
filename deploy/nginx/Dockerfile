FROM nginx:1.21.6-alpine
COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=meuhorario2_web:latest /app/public /app/public
