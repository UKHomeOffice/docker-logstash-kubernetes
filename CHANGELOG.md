# CHANGELOG

## 6.8.1-1

Upgrades Logstash to version 6.8.1: https://www.elastic.co/guide/en/logstash/6.8/releasenotes.html

Bumps journald plugin version

Installs statsd plugin as no longer part of the standard install.

The following environment variables are ADDED:

* `LS_NODE_NAME`
* `LS_HTTP_HOST`

Options added to README:

* `LS_JAVA_OPTS`

The following environment variables are REMOVED (unused):

* `LS_LOG_DIR`

## 5.6.16-1

Upgrades Logstash to version 5.6.16: https://www.elastic.co/guide/en/logstash/5.6/releasenotes.html

Added options:

- LS_MONITORING_ENABLE - Whether to enable Logstash xpack monitoring. Default: `false`
- ELASTICSEARCH_SCHEME - Elasticsearch HTTP scheme. Default: `http`.

### Notes:

`ELASTICSEARCH_SCHEME` should be set to `https` where appropriate, but is only actually used when LS_MONITORING_ENABLE is `true`.

Elasticsearch outputs with `document_type` are deprecated as they are not supported in version 6 or over: https://www.elastic.co/guide/en/elasticsearch/reference/6.0/removal-of-types.html

The following, for example, should be removed:

```
      document_type => "kubernetes"
```

If in doubt, check Management > Upgrade Assistant > Indices in Kibana, which was added in v5.6, or the deprecation messages in log output.

# END
