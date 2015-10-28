# docker-logstash-kubernetes

Logstash container for pulling docker logs with kubernetes metadata support.
Additionally logs are pulled from systemd journal too. Events can be pushed to
Cloudwatch Logs.

Logstash tails docker logs and extracts `pod`, `container_name`, `namespace`,
etc. The way this works is very simple. Logstash looks at an event field which
contains full path to kubelet created symlinks to docker container logs, and
extracts useful information from a symlink name. No access to Kubernetes API
is required.

Events are then pushed to Cloudwatch logs. An example event in Cloudwatch Logs
looks like below:

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

### Logstash

- `LS_HEAP_SIZE` - logstash JVM heap size. Defaults to `500m`.

### Cloudwatch Logs

- `OUTPUT_CLOUDWATCH` - whether to enable this output. Defaults to `true`.
- `AWS_REGION` - defaults to `eu-west-1`.
- `AWS_ACCESS_KEY_ID` - must be set.
- `AWS_SECRET_ACCESS_KEY` - must be set.
- `LOG_GROUP_NAME` - Cloudwatch logs group name. Defaults to `logstash`.
- `LOG_STREAM_NAME` - Cloudwatch logs stream name. Defaults to `hostname()`.

### Gelf Logs

- OUTPUT_GELF - whether to enable this output. Defaults to `false`
- GELF_HOST - the hostname of a gelf server to send the messages to 
- GELF_PORT - the port for use on the gelf server. Default to 12201

## Running

```
$ docker run -ti --rm \
    -v /var/lib/logstash-kubernetes:/var/lib/logstash \
    -v /var/log/journal:/var/log/journal:ro \
    -v /var/lib/docker/containers:/var/lib/docker/containers \
    -v /var/log/containers:/var/log/containers \
    -e AWS_REGION=us-west-1 \
    -e AWS_ACCESS_KEY_ID=<REPLACE ME> \
    -e AWS_SECRET_ACCESS_KEY=<REPLACE ME> \
    quay.io/ukhomeofficedigital/logstash-kubernetes:latest
```

```
$ docker run -ti --rm \
    -v /var/lib/logstash-kubernetes:/var/lib/logstash \
    -v /var/log/journal:/var/log/journal:ro \
    -v /var/lib/docker/containers:/var/lib/docker/containers \
    -v /var/log/containers:/var/log/containers \
    -e OUTPUT_CLOUDWATCH=false \
    -e OUTPUT_GELF=true \
    -e GELF_HOST=<REPLACE ME> \
    quay.io/ukhomeofficedigital/logstash-kubernetes:latest
```
