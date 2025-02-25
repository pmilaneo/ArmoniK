locals {
  mongodb_persistent_volume = (try(var.mongodb.persistent_volume.storage_provisioner, "") == "efs.csi.aws.com" ? {
    storage_provisioner = var.mongodb.persistent_volume.storage_provisioner
    resources           = var.mongodb.persistent_volume.resources
    parameters = merge(var.mongodb.persistent_volume.parameters, {
      provisioningMode = "efs-ap"
      fileSystemId     = module.efs_persistent_volume[0].efs_id
      directoryPerms   = "755"
      gidRangeStart    = "999"      # optional
      gidRangeEnd      = "2000"     # optional
      basePath         = "/mongodb" # optional
    })
  } : null)
}

# AWS S3 as shared storage
module "s3_fs" {
  source = "./generated/infra-modules/storage/aws/s3"
  tags   = local.tags
  name   = "${local.prefix}-s3fs"
  s3 = {
    policy                                = var.s3_fs.policy
    attach_policy                         = var.s3_fs.attach_policy
    attach_deny_insecure_transport_policy = var.s3_fs.attach_deny_insecure_transport_policy
    attach_require_latest_tls_policy      = var.s3_fs.attach_require_latest_tls_policy
    attach_public_policy                  = var.s3_fs.attach_public_policy
    block_public_acls                     = var.s3_fs.attach_public_policy
    block_public_policy                   = var.s3_fs.block_public_acls
    ignore_public_acls                    = var.s3_fs.block_public_policy
    restrict_public_buckets               = var.s3_fs.restrict_public_buckets
    kms_key_id                            = local.kms_key
    sse_algorithm                         = can(coalesce(var.kms_key)) ? var.s3_fs.sse_algorithm : "aws:kms"
    ownership                             = var.s3_fs.ownership
    versioning                            = var.s3_fs.versioning
  }
}

# Shared storage
resource "kubernetes_secret" "shared_storage" {
  metadata {
    name      = "shared-storage"
    namespace = local.namespace
  }
  data = {
    service_url           = "https://s3.${var.region}.amazonaws.com"
    kms_key_id            = module.s3_fs.kms_key_id
    name                  = module.s3_fs.s3_bucket_name
    access_key_id         = ""
    secret_access_key     = ""
    file_storage_type     = "S3"
    must_force_path_style = false
  }
}

# AWS S3 as object storage
module "s3_os" {
  count  = var.s3_os != null ? 1 : 0
  source = "./generated/infra-modules/storage/aws/s3"
  tags   = local.tags
  name   = "${local.prefix}-s3os"
  s3 = {
    policy                                = var.s3_os.policy
    attach_policy                         = var.s3_os.attach_policy
    attach_deny_insecure_transport_policy = var.s3_os.attach_deny_insecure_transport_policy
    attach_require_latest_tls_policy      = var.s3_os.attach_require_latest_tls_policy
    attach_public_policy                  = var.s3_os.attach_public_policy
    block_public_acls                     = var.s3_os.attach_public_policy
    block_public_policy                   = var.s3_os.block_public_acls
    ignore_public_acls                    = var.s3_os.block_public_policy
    restrict_public_buckets               = var.s3_os.restrict_public_buckets
    kms_key_id                            = local.kms_key
    sse_algorithm                         = can(coalesce(var.kms_key)) ? var.s3_os.sse_algorithm : "aws:kms"
    ownership                             = var.s3_os.ownership
    versioning                            = var.s3_os.versioning
  }
}

resource "kubernetes_secret" "s3" {
  count = length(module.s3_os) > 0 ? 1 : 0
  metadata {
    name      = "s3"
    namespace = local.namespace
  }
  data = {
    username              = ""
    password              = ""
    url                   = "https://s3.${var.region}.amazonaws.com"
    bucket_name           = module.s3_os[0].s3_bucket_name
    kms_key_id            = module.s3_os[0].kms_key_id
    must_force_path_style = false
  }
}

# AWS Elasticache
module "elasticache" {
  count  = var.elasticache != null ? 1 : 0
  source = "./generated/infra-modules/storage/aws/elasticache"
  tags   = local.tags
  name   = "${local.prefix}-elasticache"
  vpc    = local.vpc
  elasticache = {
    engine                      = var.elasticache.engine
    engine_version              = var.elasticache.engine_version
    node_type                   = var.elasticache.node_type
    apply_immediately           = var.elasticache.apply_immediately
    multi_az_enabled            = var.elasticache.multi_az_enabled
    automatic_failover_enabled  = var.elasticache.automatic_failover_enabled
    num_cache_clusters          = var.elasticache.num_cache_clusters
    preferred_cache_cluster_azs = var.elasticache.preferred_cache_cluster_azs
    data_tiering_enabled        = var.elasticache.data_tiering_enabled
    log_retention_in_days       = var.elasticache.log_retention_in_days
    cloudwatch_log_groups       = var.elasticache.cloudwatch_log_groups
    encryption_keys = {
      kms_key_id     = local.kms_key
      log_kms_key_id = local.kms_key
    }
  }
}

resource "kubernetes_secret" "elasticache" {
  count = length(module.elasticache) > 0 ? 1 : 0
  metadata {
    name      = "redis"
    namespace = local.namespace
  }
  data = {
    "chain.pem" = ""
    username    = ""
    password    = ""
    host        = module.elasticache[0].redis_endpoint_url.host
    port        = module.elasticache[0].redis_endpoint_url.port
    url         = module.elasticache[0].redis_endpoint_url.url
  }
}

# Amazon MQ
module "mq" {
  source = "./generated/infra-modules/storage/aws/mq"
  tags   = local.tags
  name   = "${local.prefix}-mq"
  vpc    = local.vpc
  user   = var.mq_credentials
  mq = {
    engine_type             = var.mq.engine_type
    engine_version          = var.mq.engine_version
    host_instance_type      = var.mq.host_instance_type
    apply_immediately       = var.mq.apply_immediately
    deployment_mode         = var.mq.deployment_mode
    storage_type            = var.mq.storage_type
    authentication_strategy = var.mq.authentication_strategy
    publicly_accessible     = var.mq.publicly_accessible
    kms_key_id              = local.kms_key
  }
}

resource "kubernetes_secret" "mq" {
  metadata {
    name      = "activemq"
    namespace = local.namespace
  }
  data = {
    "chain.pem"           = ""
    username              = module.mq.user.username
    password              = module.mq.user.password
    host                  = module.mq.activemq_endpoint_url.host
    port                  = module.mq.activemq_endpoint_url.port
    url                   = module.mq.activemq_endpoint_url.url
    web-url               = module.mq.web_url
    adapter_class_name    = local.adapter_class_name
    adapter_absolute_path = local.adapter_absolute_path
    engine_type           = module.mq.engine_type
  }
}

# MongoDB
module "mongodb" {
  source    = "./generated/infra-modules/storage/onpremise/mongodb"
  namespace = local.namespace
  mongodb = {
    image              = local.ecr_images["${var.mongodb.image_name}:${try(coalesce(var.mongodb.image_tag), "")}"].name
    tag                = local.ecr_images["${var.mongodb.image_name}:${try(coalesce(var.mongodb.image_tag), "")}"].tag
    node_selector      = var.mongodb.node_selector
    image_pull_secrets = var.mongodb.pull_secrets
    replicas_number    = var.mongodb.replicas_number
  }
  persistent_volume = local.mongodb_persistent_volume
  depends_on        = [module.efs_persistent_volume]
}

# AWS EFS as persistent volume
module "efs_persistent_volume" {
  count      = try(var.mongodb.persistent_volume.storage_provisioner, "") == "efs.csi.aws.com" ? 1 : 0
  source     = "./generated/infra-modules/persistent-volume/aws/efs"
  eks_issuer = module.eks.issuer
  vpc        = local.vpc
  efs = {
    name                            = "${local.prefix}-efs"
    kms_key_id                      = local.kms_key
    performance_mode                = var.pv_efs.efs.performance_mode
    throughput_mode                 = var.pv_efs.efs.throughput_mode
    provisioned_throughput_in_mibps = var.pv_efs.efs.provisioned_throughput_in_mibps
    transition_to_ia                = var.pv_efs.efs.transition_to_ia
    access_point                    = var.pv_efs.efs.access_point
  }
  csi_driver = {
    name               = "${local.prefix}-efs-csi-driver"
    namespace          = var.pv_efs.csi_driver.namespace
    image_pull_secrets = var.pv_efs.csi_driver.pull_secrets
    node_selector      = var.pv_efs.csi_driver.node_selector
    repository         = try(coalesce(var.pv_efs.csi_driver.repository), var.helm_charts.efs_csi_driver.repository)
    version            = try(coalesce(var.pv_efs.csi_driver.verison), var.helm_charts.efs_csi_driver.version)
    docker_images = {
      efs_csi               = local.ecr_images["${var.pv_efs.csi_driver.images.efs_csi.name}:${try(coalesce(var.pv_efs.csi_driver.images.efs_csi.tag), "")}"]
      livenessprobe         = local.ecr_images["${var.pv_efs.csi_driver.images.livenessprobe.name}:${try(coalesce(var.pv_efs.csi_driver.images.livenessprobe.tag), "")}"]
      node_driver_registrar = local.ecr_images["${var.pv_efs.csi_driver.images.node_driver_registrar.name}:${try(coalesce(var.pv_efs.csi_driver.images.node_driver_registrar.tag), "")}"]
      external_provisioner  = local.ecr_images["${var.pv_efs.csi_driver.images.external_provisioner.name}:${try(coalesce(var.pv_efs.csi_driver.images.external_provisioner.tag), "")}"]
    }
  }
  tags = local.tags
}

# Decrypt objects in S3
data "aws_iam_policy_document" "decrypt_object" {
  statement {
    sid = "KMSAccess"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    resources = toset([
      for _, s3 in local.aws_s3 :
      s3.kms_key_id
    ])
  }
}

resource "aws_iam_policy" "decrypt_object" {
  name_prefix = "${local.prefix}-s3-encrypt-decrypt"
  description = "Policy for alowing decryption of encrypted object in S3 ${module.eks.cluster_name}"
  policy      = data.aws_iam_policy_document.decrypt_object.json
  tags        = local.tags
}

resource "aws_iam_policy_attachment" "decrypt_object" {
  name       = "${local.prefix}-s3-encrypt-decrypt"
  roles      = module.eks.worker_iam_role_names
  policy_arn = aws_iam_policy.decrypt_object.arn
}

# object permissions for S3
data "aws_iam_policy_document" "object" {
  for_each = local.aws_s3
  statement {
    sid     = each.value.permission_sid
    actions = each.value.permission_actions
    effect  = "Allow"
    resources = [
      "${each.value.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "object" {
  for_each    = data.aws_iam_policy_document.object
  name_prefix = "${local.prefix}-s3-${each.key}"
  description = "Policy for allowing object access in ${each.key} S3 ${module.eks.cluster_name}"
  policy      = each.value.json
  tags        = local.tags
}

resource "aws_iam_policy_attachment" "object" {
  for_each   = aws_iam_policy.object
  name       = "${local.prefix}-permissions-on-s3-${each.key}"
  roles      = module.eks.worker_iam_role_names
  policy_arn = each.value.arn
}

resource "kubernetes_secret" "deployed_object_storage" {
  metadata {
    name      = "deployed-object-storage"
    namespace = local.namespace
  }
  data = {
    list    = join(",", local.storage_endpoint_url.deployed_object_storages)
    adapter = local.storage_endpoint_url.object_storage_adapter
  }
}

resource "kubernetes_secret" "deployed_table_storage" {
  metadata {
    name      = "deployed-table-storage"
    namespace = local.namespace
  }
  data = {
    list    = join(",", local.storage_endpoint_url.deployed_table_storages)
    adapter = local.storage_endpoint_url.table_storage_adapter
  }
}

resource "kubernetes_secret" "deployed_queue_storage" {
  metadata {
    name      = "deployed-queue-storage"
    namespace = local.namespace
  }
  data = {
    list                  = join(",", local.storage_endpoint_url.deployed_queue_storages)
    adapter               = local.storage_endpoint_url.queue_storage_adapter
    adapter_class_name    = local.adapter_class_name
    adapter_absolute_path = local.adapter_absolute_path
  }
}

locals {
  aws_s3 = merge(
    {
      fs = merge(
        module.s3_fs,
        {
          permission_sid = "ReadFromS3"
          permission_actions = [
            "s3:GetObject"
          ]
        }
      )
    },
    length(module.s3_os) == 0 ? {} : {
      os = merge(
        module.s3_os[0],
        {
          permission_sid = "FullAccessFromS3"
          permission_actions = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject",
            "s3:PutObjectAcl",
            "s3:PutObjectTagging",
          ]
        }
      )
    },
  )
  storage_endpoint_url = {
    object_storage_adapter = try(coalesce(
      length(module.elasticache) > 0 ? "Redis" : null,
      length(module.s3_os) > 0 ? "S3" : null,
    ), "")
    table_storage_adapter = "MongoDB"
    queue_storage_adapter = "Amqp"
    deployed_object_storages = concat(
      length(module.elasticache) > 0 ? ["Redis"] : [],
      length(module.s3_os) > 0 ? ["S3"] : [],
    )
    deployed_table_storages = ["MongoDB"]
    deployed_queue_storages = ["Amqp"]
    activemq = {
      url     = module.mq.activemq_endpoint_url.url
      web_url = module.mq.web_url
    }
    redis = length(module.elasticache) > 0 ? {
      url = module.elasticache[0].redis_endpoint_url.url
    } : null
    s3 = length(module.s3_os) > 0 ? {
      url         = "https://s3.${var.region}.amazonaws.com"
      bucket_name = module.s3_os[0].s3_bucket_name
      kms_key_id  = module.s3_os[0].kms_key_id
    } : null
    mongodb = {
      url                = module.mongodb.url
      number_of_replicas = var.mongodb.replicas_number
    }
    shared = {
      service_url = "https://s3.${var.region}.amazonaws.com"
      kms_key_id  = module.s3_fs.kms_key_id
      name        = module.s3_fs.s3_bucket_name
    }
  }
}
