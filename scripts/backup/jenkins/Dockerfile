# Jenkins local para testar o pipeline de backup (scripts/backup/Jenkinsfile).
# Traz o cliente Docker, porque o Jenkinsfile usa "agent { dockerfile ... }" e
# sobe o agente pelo Docker do host (socket montado no docker-compose.yml).
FROM jenkins/jenkins:lts-jdk21

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
      > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends docker-ce-cli \
 && rm -rf /var/lib/apt/lists/*
USER jenkins

# Plugins exigidos pelo Jenkinsfile do backup.
RUN jenkins-plugin-cli --plugins workflow-aggregator docker-workflow credentials-binding git
