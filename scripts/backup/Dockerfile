# Agente do Jenkins para o backup do Corlix Hub: Java 21 + Oracle SQLcl + git
# (o git é usado pelo extrair-no-projeto.sh para conferir alterações locais).
# Usado pelo scripts/backup/Jenkinsfile (agent dockerfile).
FROM eclipse-temurin:21-jre

# Mesma versão usada no desenvolvimento. Para atualizar, troque pela versão
# listada em https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/
ARG SQLCL_VERSAO=26.2.2.233.1901

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl unzip git \
 && curl -fsSL "https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-${SQLCL_VERSAO}.zip" -o /tmp/sqlcl.zip \
 && unzip -q /tmp/sqlcl.zip -d /opt \
 && rm -f /tmp/sqlcl.zip \
 && apt-get purge -y unzip \
 && rm -rf /var/lib/apt/lists/*

# O Jenkins roda o container com o UID do agente, sem home gravável.
ENV PATH=/opt/sqlcl/bin:$PATH \
    HOME=/tmp
