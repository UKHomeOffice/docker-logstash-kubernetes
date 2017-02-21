#!/usr/bin/bash

export HOME=/var/lib/logstash

: ${LS_LOG_LEVEL:=error}
: ${LS_HEAP_SIZE:=500m}
: ${LS_JAVA_OPTS:=-Djava.io.tmpdir=${HOME}}
: ${LS_LOG_DIR:=/var/lib/logstash}
: ${LS_OPEN_FILES:=8192}
: ${LS_PIPELINE_BATCH_SIZE:=125}

: ${INPUT_JOURNALD:=true}
: ${INPUT_KUBERNETES_AUDIT:=true}

: ${OUTPUT_ELASTICSEARCH:=true}
: ${ELASTICSEARCH_HOST:=127.0.0.1:9200}
: ${ELASTICSEARCH_SSL_ENABLED:=false}
: ${ELASTICSEARCH_CERTIFICATE_VERIFICATION:=true}
: ${ELASTICSEARCH_USER:=}
: ${ELASTICSEARCH_PASSWORD:=}

: ${ELASTICSEARCH_INDEX_SUFFIX:=""}
: ${ELASTICSEARCH_FLUSH_SIZE:=500}
: ${ELASTICSEARCH_IDLE_FLUSH_TIME:=1}


if [[ ${INPUT_JOURNALD} != 'true' ]]; then
  rm -f /logstash/conf.d/10_input_journald.conf
fi

if [[ ${INPUT_KUBERNETES_AUDIT} != 'true' ]]; then
  rm -f /logstash/conf.d/10_input_kubernetes_audit.conf
fi


if [[ ${OUTPUT_ELASTICSEARCH} != 'true' ]]; then
  rm -f /logstash/conf.d/20_output_journald_elasticsearch.conf
  rm -f /logstash/conf.d/20_output_kubernetes_elasticsearch.conf
  rm -f /logstash/conf.d/20_output_kubernetes_audit_elasticsearch.conf
else
  sed -e "s/%ELASTICSEARCH_HOST%/${ELASTICSEARCH_HOST}/" \
      -e "s/%ELASTICSEARCH_SSL_ENABLED%/${ELASTICSEARCH_SSL_ENABLED}/" \
      -e "s/%ELASTICSEARCH_CERTIFICATE_VERIFICATION%/${ELASTICSEARCH_CERTIFICATE_VERIFICATION}/" \
      -e "s/%ELASTICSEARCH_USER%/${ELASTICSEARCH_USER}/" \
      -e "s/%ELASTICSEARCH_PASSWORD%/${ELASTICSEARCH_PASSWORD}/" \
      -e "s/%ELASTICSEARCH_INDEX_SUFFIX%/${ELASTICSEARCH_INDEX_SUFFIX}/" \
      -e "s/%ELASTICSEARCH_FLUSH_SIZE%/${ELASTICSEARCH_FLUSH_SIZE}/" \
      -e "s/%ELASTICSEARCH_IDLE_FLUSH_TIME%/${ELASTICSEARCH_IDLE_FLUSH_TIME}/" \
      -i /logstash/conf.d/20_output_kubernetes_elasticsearch.conf \
      -i /logstash/conf.d/20_output_kubernetes_audit_elasticsearch.conf \
      -i /logstash/conf.d/20_output_journald_elasticsearch.conf
fi


ulimit -n ${LS_OPEN_FILES} > /dev/null

exec /logstash/bin/logstash --log.format json \
  --log.level ${LS_LOG_LEVEL} \
  --pipeline.batch.size ${LS_PIPELINE_BATCH_SIZE} \
  --config.reload.automatic \
  -f "/logstash/conf.d/**/*.conf" \
  ${LOGSTASH_ARGS}
