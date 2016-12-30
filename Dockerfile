FROM fedora:25

RUN dnf upgrade -y -q && \
    dnf clean all && \
    dnf install -y -q java-headless which hostname tar wget && \
    dnf clean all

ENV LS_VERSION 2.4.1
RUN wget -q https://download.elastic.co/logstash/logstash/logstash-${LS_VERSION}.tar.gz -O - | tar -xzf -; \
  mv logstash-${LS_VERSION} /logstash

RUN /logstash/bin/logstash-plugin install --version 2.7.1 logstash-output-elasticsearch && \
    /logstash/bin/logstash-plugin install logstash-filter-kubernetes && \
    /logstash/bin/logstash-plugin install logstash-input-journald && \
    /logstash/bin/logstash-plugin install logstash-input-http && \
    /logstash/bin/logstash-plugin install --version 2.0.0.pre1 logstash-output-cloudwatchlogs

COPY run.sh /run.sh
COPY conf.d/ /logstash/conf.d/

WORKDIR /var/lib/logstash
VOLUME /var/lib/logstash

ENTRYPOINT ["/run.sh"]
