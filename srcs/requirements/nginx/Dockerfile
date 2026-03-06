#FROM nginx:alpine

#RUN rm /etc/nginx/conf.d/default.conf

#COPY conf/default.cong=f /etc/nginx/conf.d/

#EXPOSE 80

#CMD ["nginx", "-g", "daemon off;"]

# OU 
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	&& apt-get clean

#creer le dossier SSL
RUN mkdir -p /etc/nginx/ssl

RUN openssl req -x509 -nodes \
	-out /etc/nginx/ssl/inception.crt \
	-keyout /etc/nginx/ssl/inception.key \
	-subj "/C=FR/ST=IDF/L=Paris/O=42/OU=student/CN=makoon.42.fr" \
	-days 365

#copier la config nginx
COPY conf/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]