# docker-logstash-kubernetes

Logstash container for pulling docker logs with kubernetes metadata support.
Additionally logs are pulled from systemd journal too. Events can be pushed to
Cloudwatch Logs and or ElasticSearch.

Logstash tails docker logs and extracts `pod`, `container_name`, `namespace`,
etc. The way this works is very simple. Logstash looks at an event field which
contains full path to kubelet created symlinks to docker container logs, and
extracts useful information from a symlink name. No access to Kubernetes API
is required.

Events can then pushed to Cloudwatch logs (disabled by default). An example
event in Cloudwatch Logs looks like below:

```json
{
    "log": "10.10.112.0 - - [02/Oct/2015:15:20:38 +0000] \"GET /dataset HTTP/1.1\" 200 2 \"-\" \"axios/0.5.4\" 6\n",
    "stream": "stdout",
    "time": "2015-10-02T15:20:38.706043658Z",
    "replication_controller": "data-example-api",
    "pod": "data-example-api-p82sy",
    "namespace": "hoapi-catalogue",
    "container_name": "data-example-api",
    "container_id": "df1874255f0c85d18747b5edfc8dc372dbebf725b9ccbfb37549f5f81bba8326"
}
```

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

If you want to push events to Cloudwatch Logs, then you will have to set AWS
access keys via environment variables.


## Configuration

As usual, configuration is passed through environment variables.

- `LS_HEAP_SIZE` - logstash JVM heap size. Defaults to `500m`.
- `OUTPUT_CLOUDWATCH` - whether to enable this output. Defaults to `false`.
- `AWS_REGION` - defaults to `eu-west-1`.
- `AWS_ACCESS_KEY_ID` - must be set.
- `AWS_SECRET_ACCESS_KEY` - must be set.
- `LOG_GROUP_NAME` - Cloudwatch logs group name. Defaults to `logstash`.
- `LOG_STREAM_NAME` - Cloudwatch logs stream name. Defaults to `hostname()`.
- `INPUT_JOURNALD` - Enable logs ingestion from journald. Default: `true`.
- `OUTPUT_ELASTICSEARCH` - Enable logs output to ElasticSearch. Default `true`.
- `ELASTICSEARCH_HOST` - ElasticSearch host, can be comma separated. Default: `127.0.0.1:9200`.
- `ELASTICSEARCH_INDEX_SUFFIX` - ElasticSearch index suffix. Default: `""`.
- `LOGSTASH_ARGS` - Sets additional logstash command line arguments.


## Running

```
$ docker run -ti --rm \
    -v /var/lib/logstash-kubernetes:/var/lib/logstash:z \
    -v /var/log/journal:/var/log/journal:ro \
    -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
    -v /var/log/containers:/var/log/containers:ro \
    -e ELASTICSEARCH_HOST=my-est-host.local:9200 \
    quay.io/ukhomeofficedigital/logstash-kubernetes:v0.4.1
```


### Running in Kubernetes

```
$ kubectl create -f logstash-daemonset.yaml
```
