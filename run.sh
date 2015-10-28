#!/usr/bin/bash

: ${LS_HOME:=/var/lib/logstash}
: ${HOME:=${LS_HOME}}
: ${LS_HEAP_SIZE:=500m}
: ${LS_JAVA_OPTS:=-Djava.io.tmpdir=${LS_HOME}}
: ${LS_LOG_DIR:=/var/log/logstash}
: ${OUTPUT_CLOUDWATCH:=true}
: ${AWS_REGION:=eu-west-1}
: ${LOG_GROUP_NAME:=logstash}
: ${LOG_STREAM_NAME:=$(hostname)}
: ${OUTPUT_GELF:=false}
: ${GELF_HOST:=""}
: ${GELF_PORT:=12201}

sed -e "s/%GELF_HOST%/${GELF_HOST}/" \
    -e "s/%GELF_PORT%/${GELF_PORT}/" \
    -i /etc/logstash/conf.d/21_output_kubernetes_gelf.conf \
    -i /etc/logstash/conf.d/21_output_journald_gelf.conf

sed -e "s/%AWS_REGION%/${AWS_REGION}/" \
    -e "s/%LOG_GROUP_NAME%/${LOG_GROUP_NAME}/" \
    -e "s/%LOG_STREAM_NAME%/${LOG_STREAM_NAME}/" \
    -i /etc/logstash/conf.d/20_output_kubernetes_cloudwatch.conf \
    -i /etc/logstash/conf.d/20_output_journald_cloudwatch.conf

if [[ ${OUTPUT_CLOUDWATCH} != 'true' ]]; then
  rm -f /etc/logstash/conf.d/20_output_kubernetes_cloudwatch.conf
  rm -f /etc/logstash/conf.d/20_output_journald_cloudwatch.conf
fi

if [[ ${OUTPUT_GELF} != "true" ]]; then
  rm -f /etc/logstash/conf.d/21_output_kubernetes_gelf.conf
  rm -f /etc/logstash/conf.d/21_output_journald_gelf.conf
fi

ulimit -n ${LS_OPEN_FILES} > /dev/null
cd ${LS_HOME}

/opt/logstash/bin/logstash -f /etc/logstash/conf.d
