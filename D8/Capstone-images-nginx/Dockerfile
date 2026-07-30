FROM nginx:alpine

# Copy template
COPY index.template.html /usr/share/nginx/html/index.template.html

# Copy startup script
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]