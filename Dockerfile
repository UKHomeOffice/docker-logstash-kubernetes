# Added build step to get the patched 3s endpoint PR
FROM alpine:latest as s3endpointpatch
RUN apk --no-cache add git
WORKDIR /root/
RUN git clone https://github.com/logstash-plugins/logstash-output-s3

# This fails with conflicts in the documentation and contributers only - the file has the patch
RUN cd logstash-output-s3 && \
    git fetch origin pull/100/head:custom-endpoint && \
    git checkout v4.0.10 && \
    git config user.email "robot@nowhere" && \
    git config user.name "Anon" && \
    git merge custom-endpoint -m "justdoit" || true

FROM fedora:25

RUN dnf upgrade -y -q && \
    dnf clean all && \
    dnf install -y -q java-headless which hostname tar wget && \
    dnf clean all

ENV LS_VERSION 5.6.1

RUN wget -q https://artifacts.elastic.co/downloads/logstash/logstash-${LS_VERSION}.tar.gz -O - | tar -xzf -; \
  mv logstash-${LS_VERSION} /logstash

RUN JARS_SKIP=true /logstash/bin/logstash-plugin install --version 0.3.1 logstash-filter-kubernetes && \
    JARS_SKIP=true /logstash/bin/logstash-plugin install --version 2.0.0 logstash-input-journald

# Add patched version of S3 handler until this is merged:
RUN rm -fr /logstash/vendor/bundle/jruby/1.9/gems/logstash-output-s3-4.0.10
COPY --from=s3endpointpatch /root/logstash-output-s3 /logstash/vendor/bundle/jruby/1.9/gems/logstash-output-s3-4.0.10
COPY run.sh /run.sh
COPY conf.d/ /logstash/conf.d/

COPY config/log4j2.properties /logstash/config/log4j2.properties

WORKDIR /var/lib/logstash
VOLUME /var/lib/logstash

ENTRYPOINT ["/run.sh"]
