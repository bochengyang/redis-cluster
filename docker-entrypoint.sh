#!/bin/sh
set -e

if [ "$1" = 'redis-server' ]; then
	startfilebeat=0

	if [ "$REDISPASSWORD" ]; then
		if [ "$STANDALONE" = 1 ]; then
			echo "requirepass $REDISPASSWORD" >> /conf/master.conf
		elif [ "$ACT_MASTER" = 1 ]; then
			echo "requirepass $REDISPASSWORD" >> /conf/master.conf
            echo "masterauth $REDISPASSWORD" >> /conf/master.conf
			echo "sentinel auth-pass redis-cluster $REDISPASSWORD" >> /conf/master_sentinel.conf
		elif [ "$ACT_SLAVE" = 1 ]; then
			echo "requirepass $REDISPASSWORD" >> /conf/slave.conf
			echo "masterauth $REDISPASSWORD" >> /conf/slave.conf
			echo "sentinel auth-pass redis-cluster $REDISPASSWORD" >> /conf/slave_sentinel.conf
		elif [ "$ACT_SENTINEL" = 1 ]; then
			echo "sentinel auth-pass redis-cluster $REDISPASSWORD" >> /conf/sentinel_only.conf
		fi
	fi
	
	if [ "$STANDALONE" = 1 ]; then
		redis-server /conf/master.conf &
		startfilebeat=1
	elif [ "$ACT_MASTER" = 1 ]; then
		# string replacement for configuration
		cat /conf/master_sentinel.conf | sed "s/REDIS_MASTER_HOSTNAME/$REDIS_MASTER_HOSTNAME/" | sed "s/SENTINEL_QUORUM/$SENTINEL_QUORUM/" > /conf/master_sentinel.conf.tmp
		cat /conf/master_sentinel.conf.tmp > /conf/master_sentinel.conf
		rm /conf/master_sentinel.conf.tmp

		redis-server /conf/master.conf &
		redis-sentinel /conf/master_sentinel.conf &
		startfilebeat=1
	elif [ "$ACT_SLAVE" = 1 ]; then
		# string replacement for configuration
		cat /conf/slave.conf | sed "s/REDIS_MASTER_HOSTNAME/$REDIS_MASTER_HOSTNAME/" > /conf/slave.conf.tmp
		cat /conf/slave.conf.tmp > /conf/slave.conf
		rm /conf/slave.conf.tmp
		cat /conf/slave_sentinel.conf | sed "s/REDIS_MASTER_HOSTNAME/$REDIS_MASTER_HOSTNAME/" | sed "s/SENTINEL_QUORUM/$SENTINEL_QUORUM/" > /conf/slave_sentinel.conf.tmp
		cat /conf/slave_sentinel.conf.tmp > /conf/slave_sentinel.conf
		rm /conf/slave_sentinel.conf.tmp

                redis-server /conf/slave.conf &
                redis-sentinel /conf/slave_sentinel.conf &
		startfilebeat=1
	elif [ "$ACT_SENTINEL" = 1 ]; then
		# string replacement for configuration
		cat /conf/sentinel_only.conf | sed "s/REDIS_MASTER_HOSTNAME/$REDIS_MASTER_HOSTNAME/" | sed "s/SENTINEL_QUORUM/$SENTINEL_QUORUM/" > /conf/sentinel_only.conf.tmp
		cat /conf/sentinel_only.conf.tmp > /conf/sentinel_only.conf
		rm /conf/sentinel_only.conf.tmp

		redis-sentinel /conf/sentinel_only.conf &
		startfilebeat=1
	else
		echo "You have not specified STANDALONE, ACT_MASTER, ACT_SLAVE or ACT_SENTINEL in your environment variable"
	fi

	if [ "$startfilebeat" = 1 ]; then
		# execute filebeat for logging transmit
		cat /filebeat.yml | sed "s/LOGSTASH_STRING/$LOGSTASH_STRING/" > /filebeat.yml.tmp
		cat /filebeat.yml.tmp > /filebeat.yml
		rm /filebeat.yml.tmp
		/filebeat -c /filebeat.yml
	fi
else
	exec "$@"
fi
