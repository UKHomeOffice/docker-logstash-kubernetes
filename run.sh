#!/usr/bin/bash

export HOME=/var/lib/logstash

: ${LS_LOG_LEVEL:=error}
: ${LS_HEAP_SIZE:=500m}
: ${LS_JAVA_OPTS:=-Djava.io.tmpdir=${HOME}}
: ${LS_LOG_DIR:=/var/lib/logstash}
: ${LS_OPEN_FILES:=8192}
: ${LS_PIPELINE_BATCH_SIZE:=125}
: ${LS_MONITORING_ENABLE:=false}
: ${LS_NODE_NAME:=$HOSTNAME}
: ${LS_HTTP_HOST:=0.0.0.0}
: ${INPUT_KUBERNETES_EXCLUDE_PATTERNS:=}
: ${INPUT_KUBERNETES_FILE_CHUNK_COUNT:=32} # 1MB chunks as default chunk size is 32KB
: ${INPUT_KUBERNETES_FILE_CHUNK_SIZE:=32768} # 32KB
: ${INPUT_JOURNALD:=true}
: ${INPUT_KUBERNETES_AUDIT:=true}
: ${INPUT_KUBERNETES:=true}

: ${OUTPUT_ELASTICSEARCH:=true}
: ${ELASTICSEARCH_HOST:=127.0.0.1:9200}
: ${ELASTICSEARCH_SCHEME:=http}
: ${ELASTICSEARCH_SSL_ENABLED:=false}
: ${ELASTICSEARCH_CA_CERTIFICATE_PATH:=/etc/pki/tls/certs/ca-bundle.crt}
: ${ELASTICSEARCH_CERTIFICATE_VERIFICATION:=true}
: ${ELASTICSEARCH_USER:=}
: ${ELASTICSEARCH_PASSWORD:=}
: ${ELASTICSEARCH_HTTP_COMPRESSION_ENABLED:=true}

: ${ELASTICSEARCH_INDEX_SUFFIX:=""}

[ ${ELASTICSEARCH_SSL_ENABLED} == "true" ] && export ELASTICSEARCH_SCHEME="https"

# exclude certain kubernetes log files if provided
if [[ ${INPUT_KUBERNETES_EXCLUDE_PATTERNS} ]]; then
  sed -e "s/%INPUT_KUBERNETES_EXCLUDE_PATTERNS%/exclude => [ ${INPUT_KUBERNETES_EXCLUDE_PATTERNS} ]/" \
      -i /logstash/conf.d/10_input_kubernetes.conf
else
  sed -e "s/%INPUT_KUBERNETES_EXCLUDE_PATTERNS%//" \
      -i /logstash/conf.d/10_input_kubernetes.conf
fi

sed -e "s/%INPUT_KUBERNETES_FILE_CHUNK_COUNT%/${INPUT_KUBERNETES_FILE_CHUNK_COUNT}/" \
    -e "s/%INPUT_KUBERNETES_FILE_CHUNK_SIZE%/${INPUT_KUBERNETES_FILE_CHUNK_SIZE}/" \
    -i /logstash/conf.d/10_input_kubernetes.conf

if [[ ${INPUT_JOURNALD} != 'true' ]]; then
  rm -f /logstash/conf.d/10_input_journald.conf
fi

if [[ ${INPUT_KUBERNETES_AUDIT} != 'true' ]]; then
  rm -f /logstash/conf.d/10_input_kubernetes_audit.conf
fi

if [[ ${INPUT_KUBERNETES} != 'true' ]]; then
  rm -f /logstash/conf.d/10_input_kubernetes.conf
fi

if [[ ${OUTPUT_ELASTICSEARCH} != 'true' ]]; then
  rm -f /logstash/conf.d/20_output_journald_elasticsearch.conf
  rm -f /logstash/conf.d/20_output_kubernetes_elasticsearch.conf
  rm -f /logstash/conf.d/20_output_kubernetes_audit_elasticsearch.conf
else
  sed -e "s/%ELASTICSEARCH_HOST%/${ELASTICSEARCH_HOST}/" \
      -e "s/%ELASTICSEARCH_SSL_ENABLED%/${ELASTICSEARCH_SSL_ENABLED}/" \
      -e "s#%ELASTICSEARCH_CA_CERTIFICATE_PATH%#${ELASTICSEARCH_CA_CERTIFICATE_PATH}#" \
      -e "s/%ELASTICSEARCH_CERTIFICATE_VERIFICATION%/${ELASTICSEARCH_CERTIFICATE_VERIFICATION}/" \
      -e "s/%ELASTICSEARCH_HTTP_COMPRESSION_ENABLED%/${ELASTICSEARCH_HTTP_COMPRESSION_ENABLED}/" \
      -e "s/%ELASTICSEARCH_USER%/${ELASTICSEARCH_USER}/" \
      -e "s/%ELASTICSEARCH_PASSWORD%/${ELASTICSEARCH_PASSWORD}/" \
      -e "s/%ELASTICSEARCH_INDEX_SUFFIX%/${ELASTICSEARCH_INDEX_SUFFIX}/" \
      -e "s/%ELASTICSEARCH_SCHEME%/${ELASTICSEARCH_SCHEME}/" \
      -e "s/%LS_MONITORING_ENABLE%/${LS_MONITORING_ENABLE}/" \
      -e "s/%LS_NODE_NAME%/${LS_NODE_NAME}/" \
      -e "s/%LS_HTTP_HOST%/${LS_HTTP_HOST}/" \
      -i /logstash/config/logstash.yml \
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
