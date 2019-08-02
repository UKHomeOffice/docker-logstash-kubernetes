# docker-logstash-kubernetes

Logstash container for pulling docker logs with kubernetes metadata support.
Additionally logs are pulled from systemd journal too.

Logstash tails docker logs and extracts `pod`, `container_name`, `namespace`,
etc. The way this works is very simple. Logstash looks at an event field which
contains full path to kubelet created symlinks to docker container logs, and
extracts useful information from a symlink name. No access to Kubernetes API
is required.

Other outputs can be added in the future.

## Requirements

You need to have kubelet process running on the host. Normally kubelet creates
symlinks to container logs from `/var/log/containers/` to
`/var/lib/docker/containers/`. So for that you need to make sure that logstash
has access to both directories.

For logstash to be able to pull logs from journal, you need to make sure that
logstash can read `/var/log/journal`.

Also, logstash writes `sincedb` file to its home directory, which by default is
`/var/lib/logstash`. If you don't want logstash to start reading docker or
journal logs from the beginning after a restart, make sure you mount
`/var/lib/logstash` somewhere on the host.

## Configuration

As usual, configuration is passed through environment variables.

- `LS_HEAP_SIZE` - Logstash JVM heap size. Defaults to `500m`.
- `LS_LOG_LEVEL` - Logstash log level. Default: `error`.
- `LS_NODE_NAME` - Logstash node name reported to ES if `LS_MONITORING_ENABLE=true`. Default: `$HOSTNAME`
- `LS_PIPELINE_BATCH_SIZE` - Size of batches the pipeline is to work in. Default: `125`
- `LS_MONITORING_ENABLE` - Whether to enable Logstash xpack monitoring. Default: `false`
- `LS_HTTP_HOST` - Listen address. default: `0.0.0.0`.
- `LS_JAVA_OPTS` - JVM Options. Default: `-Djava.io.tmpdir=${HOME}`
- `INPUT_KUBERNETES` - Enable kubernetes logs ingestion. Default: `true`.
- `INPUT_KUBERNETES_EXCLUDE_PATTERNS` - Comma separated list of log file path patterns to be excluded from processing. Example: `"*.gz", "*.tar"`. Default: `""`.
- `INPUT_KUBERNETES_FILE_CHUNK_COUNT` - [file_chunk_count](https://www.elastic.co/guide/en/logstash/6.8/plugins-inputs-file.html#plugins-inputs-file-file_chunk_count). Default: 32.
- `INPUT_KUBERNETES_FILE_CHUNK_SIZE` - [file_chunk_size](https://www.elastic.co/guide/en/logstash/6.8/plugins-inputs-file.html#plugins-inputs-file-file_chunk_size). Default: 32768 (32KB).
- `INPUT_JOURNALD` - Enable logs ingestion from journald. Default: `true`.
- `INPUT_KUBERNETES_AUDIT` - Enable kubernetes audit logs ingestion. Default: `true`.
- `OUTPUT_ELASTICSEARCH` - Enable logs output to Elasticsearch. Default `true`.
- `ELASTICSEARCH_HOST` - Elasticsearch host, can be comma separated. Default: `127.0.0.1:9200`.
- `ELASTICSEARCH_SCHEME`- Elasticsearch HTTP scheme. Default: `http`.
- `ELASTICSEARCH_SSL_ENABLED` - Elasticsearch SSL flag. Default: `false`.
- `ELASTICSEARCH_CA_CERTIFICATE_PATH` - The path to the .pem file that contains the Certificate Authority’s certificate.
- `ELASTICSEARCH_CERTIFICATE_VERIFICATION` - Elasticsearch SSL cerificate verification. Default: `true`.
- `ELASTICSEARCH_HTTP_COMPRESSION_ENABLED` - Elasticsearch HTTP compression. Default: `true`.
- `ELASTICSEARCH_USER` - Elasticsearch basic auth username. Default: `""`.
- `ELASTICSEARCH_PASSWORD` - Elasticsarch basic auth password. Default: `""`.
- `ELASTICSEARCH_INDEX_SUFFIX` - Elasticsearch index suffix. Default: `""`.
- `LOGSTASH_ARGS` - Sets additional logstash command line arguments.

For Kubernetes audit logs it may be necessary to increase `index.mapping.total_fields.limit`. This can be achieved with Elasticsearch curator [`index_settings` action](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.1/index_settings.html).

## Running

```
$ docker run -ti --rm \
    -v /var/lib/logstash-kubernetes:/var/lib/logstash:z \
    -v /var/log/journal:/var/log/journal:ro \
    -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
    -v /var/log/containers:/var/log/containers:ro \
    -v /var/log/kubernetes:/var/log/kubernetes:ro \
    -e ELASTICSEARCH_HOST=my-est-host.local:9200 \
    quay.io/ukhomeofficedigital/logstash-kubernetes:latest
```
