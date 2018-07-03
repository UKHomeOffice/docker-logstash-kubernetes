FROM fedora:25

RUN dnf upgrade -y -q && \
    dnf clean all && \
    dnf install -y -q java-headless which hostname tar wget && \
    dnf clean all

ENV LS_VERSION 5.6.10

RUN wget -q https://artifacts.elastic.co/downloads/logstash/logstash-${LS_VERSION}.tar.gz -O - | tar -xzf -; \
  mv logstash-${LS_VERSION} /logstash

RUN JARS_SKIP=true /logstash/bin/logstash-plugin install --version 0.3.1 logstash-filter-kubernetes && \
    JARS_SKIP=true /logstash/bin/logstash-plugin install --version 2.0.0 logstash-input-journald

COPY run.sh /run.sh
COPY conf.d/ /logstash/conf.d/

COPY config/log4j2.properties /logstash/config/log4j2.properties

WORKDIR /var/lib/logstash
VOLUME /var/lib/logstash

ENTRYPOINT ["/run.sh"]
