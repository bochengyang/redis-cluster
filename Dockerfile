FROM redis:3.0.7-alpine

COPY filebeat /filebeat
COPY filebeat.yml.redis /filebeat.yml
COPY conf /conf

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD [ "redis-server" ]
