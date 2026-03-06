FROM debian:bookworm

RUN apt update && apt upgrade -y && \
	apt install mariadb-server -y && \
	rm -rf /var/lib/apt/list/*

COPY conf/my.cnf /etc/mysql/my.conf
COPY tools/init.sh /init.sh

RUN chmod +x /init.sh

EXPOSE 3306

CMD["/init.sh"]