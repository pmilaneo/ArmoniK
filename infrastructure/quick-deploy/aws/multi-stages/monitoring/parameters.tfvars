# Profile
profile = "default"

# Region
region = "eu-west-3"

# Kubeconfig path
k8s_config_path = "~/.kube/config"

# Kubeconfig context
k8s_config_context = "default"

# Kubernetes namespace
namespace = "armonik"

# SUFFIX
suffix = "main"

tags = {
  "name"             = ""
  "env"              = ""
  "entity"           = ""
  "bu"               = ""
  "owner"            = ""
  "application code" = ""
  "project code"     = ""
  "cost center"      = ""
  "Support Contact"  = ""
  "origin"           = "terraform"
  "unit of measure"  = ""
  "epic"             = ""
  "functional block" = ""
  "hostname"         = ""
  "interruptible"    = ""
  "tostop"           = ""
  "tostart"          = ""
  "branch"           = ""
  "gridserver"       = ""
  "it division"      = ""
  "Confidentiality"  = ""
  "csp"              = "aws"
  "grafanaserver"    = ""
  "Terraform"        = "true"
  "DST_Update"       = ""
}

# Monitoring infos
monitoring = {
  seq = {
    enabled                = true
    image                  = "seq"
    tag                    = "2023.3"
    port                   = 8080
    image_pull_secrets     = ""
    service_type           = "ClusterIP"
    node_selector          = { service = "monitoring" }
    system_ram_target      = 0.2
    cli_image              = "seqcli"
    cli_tag                = "2023.2"
    cli_image_pull_secrets = ""
    retention_in_days      = "2d"
  }
  grafana = {
    enabled            = true
    image              = "grafana"
    tag                = "10.0.2"
    port               = 3000
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { service = "monitoring" }
  }
  node_exporter = {
    enabled            = true
    image              = "node-exporter"
    tag                = "v1.6.0"
    image_pull_secrets = ""
    node_selector      = {}
  }
  prometheus = {
    image              = "prometheus"
    tag                = "v2.45.0"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { service = "metrics" }
  }
  metrics_exporter = {
    image              = "metrics-exporter"
    tag                = "0.14.3"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { service = "metrics" }
    extra_conf = {
      MongoDB__AllowInsecureTls              = true
      Serilog__MinimumLevel                  = "Information"
      MongoDB__TableStorage__PollingDelayMin = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax = "00:00:10"
    }
  }
  partition_metrics_exporter = {
    image              = "partition-metrics-exporter"
    tag                = "0.14.3"
    image_pull_secrets = ""
    service_type       = "ClusterIP"
    node_selector      = { service = "metrics" }
    extra_conf = {
      MongoDB__AllowInsecureTls              = true
      Serilog__MinimumLevel                  = "Information"
      MongoDB__TableStorage__PollingDelayMin = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax = "00:00:10"
    }
  }
  cloudwatch = {
    enabled           = true
    kms_key_id        = ""
    retention_in_days = 30
  }
  s3 = {
    enabled = true
    name    = "armonik-logs"
    region  = "eu-west-3"
    prefix  = "main"
    arn     = "arn:aws:s3:::armonik-logs"
  }
  fluent_bit = {
    image              = "fluent-bit"
    tag                = "2.1.7"
    image_pull_secrets = ""
    is_daemonset       = true
    http_port          = 2020 # 0 or 2020
    read_from_head     = true
    node_selector      = {}
    parser             = "cri"
  }
}

authentication = false
