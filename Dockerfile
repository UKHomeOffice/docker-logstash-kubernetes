FROM fedora:30

RUN dnf upgrade -y -q && \
    dnf clean all && \
    dnf install -y -q java-headless which hostname tar wget && \
    dnf clean all

ENV LS_VERSION 6.8.2

RUN wget -q https://artifacts.elastic.co/downloads/logstash/logstash-${LS_VERSION}.tar.gz -O - | tar -xzf -; \
  mv logstash-${LS_VERSION} /logstash

RUN JARS_SKIP=true /logstash/bin/logstash-plugin install --version 0.3.1 logstash-filter-kubernetes && \
    JARS_SKIP=true /logstash/bin/logstash-plugin install --version 2.0.2 logstash-input-journald && \
    JARS_SKIP=true /logstash/bin/logstash-plugin install --version 4.0.5 logstash-input-file && \
    JARS_SKIP=true /logstash/bin/logstash-plugin install --version 3.2.0 logstash-output-statsd && \
    JARS_SKIP=true /logstash/bin/logstash-plugin install --version 3.0.5 logstash-output-syslog
 

COPY run.sh /run.sh
COPY conf.d/ /logstash/conf.d/

COPY config/ /logstash/config/

WORKDIR /var/lib/logstash
VOLUME /var/lib/logstash

ENTRYPOINT ["/run.sh"]
