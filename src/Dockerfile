# Dockerfile for customized gitlab-ce image
FROM localhost:5000/lewis/gitlab-ce:8.17-psql_updated
MAINTAINER rhinoceromirinda@gmail.com

ENV GITLAB_BUILD_DIR="/tmp/gitlab-build" \
    APT_SOURCE_DIR="/etc/apt"    \
    CRONTAB_FILE="/etc/crontab"

COPY sources.list.xenial.example ${APT_SOURCE_DIR}/sources.list  

#COPY entrypoint.sh /sbin/entrypoint.sh
#RUN chmod 755 /sbin/entrypoint.sh


RUN apt-get update &&  \
    apt-get install -y \
    cron

RUN echo '0 2 * * * /opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1' >> ${CRONTAB_FILE} 

#ENTRYPOINT ["/sbin/entrypoint.sh"]
#CMD ["app:start"]

