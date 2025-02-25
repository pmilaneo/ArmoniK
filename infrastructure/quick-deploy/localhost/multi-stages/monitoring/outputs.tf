output "monitoring" {
  description = "Monitoring endpoint URLs"
  value = {
    seq = (var.monitoring.seq.enabled ? {
      host    = module.seq.0.host
      port    = module.seq.0.port
      url     = module.seq.0.url
      web_url = module.seq.0.web_url
      enabled = true
    } : {})
    grafana = (var.monitoring.grafana.enabled ? {
      host    = module.grafana.0.host
      port    = module.grafana.0.port
      url     = module.grafana.0.url
      enabled = true
    } : {})
    metrics_exporter = {
      name      = module.metrics_exporter.name
      host      = module.metrics_exporter.host
      port      = module.metrics_exporter.port
      url       = module.metrics_exporter.url
      namespace = module.metrics_exporter.namespace
    }
    partition_metrics_exporter = {
      name      = null #module.partition_metrics_exporter.name
      host      = null #module.partition_metrics_exporter.host
      port      = null #module.partition_metrics_exporter.port
      url       = null #module.partition_metrics_exporter.url
      namespace = null #module.partition_metrics_exporter.namespace
    }
    prometheus = {
      host = module.prometheus.host
      port = module.prometheus.port
      url  = module.prometheus.url
    }
    fluent_bit = {
      container_name = module.fluent_bit.container_name
      image          = module.fluent_bit.image
      tag            = module.fluent_bit.tag
      is_daemonset   = module.fluent_bit.is_daemonset
      configmaps = {
        envvars = module.fluent_bit.configmaps.envvars
        config  = module.fluent_bit.configmaps.config
      }
    }
  }
}
