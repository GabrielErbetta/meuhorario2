FROM nginx:1.21.6-alpine
COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=app /app/public /app/public
