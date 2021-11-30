# K8s configuration
data "external" "k8s_config_context" {
  program     = ["bash", "k8s_config.sh"]
  working_dir = "./scripts"
}

# Storage
module "storage" {
  source    = "./storage"
  namespace = var.namespace

  # Object storage : Redis
  object_storage = {
    replicas     = var.object_storage.replicas,
    port         = var.object_storage.port,
    certificates = {
      cert_file    = var.object_storage.certificates["cert_file"],
      key_file     = var.object_storage.certificates["key_file"],
      ca_cert_file = var.object_storage.certificates["ca_cert_file"]
    },
    secret       = var.object_storage.secret
  }

  # Table storage : MongoDB
  table_storage = {
    replicas = var.table_storage.replicas,
    port     = var.table_storage.port
  }

  # Queue storage : ActiveMQ
  queue_storage = {
    replicas = var.queue_storage.replicas,
    port     = var.queue_storage.port
    secret   = var.queue_storage.secret
  }

  # Shared storage (like NFS)
  shared_storage = {
    storage_class           = {
      name                   = var.shared_storage.storage_class["name"],
      provisioner            = var.shared_storage.storage_class["provisioner"],
      volume_binding_mode    = var.shared_storage.storage_class["volume_binding_mode"],
      allow_volume_expansion = var.shared_storage.storage_class["allow_volume_expansion"],
    },
    persistent_volume       = {
      name                             = var.shared_storage.persistent_volume["name"],
      persistent_volume_reclaim_policy = var.shared_storage.persistent_volume["persistent_volume_reclaim_policy"],
      access_modes                     = var.shared_storage.persistent_volume["access_modes"],
      size                             = var.shared_storage.persistent_volume["size"],
      path                             = var.shared_storage.persistent_volume["path"]
    },
    persistent_volume_claim = {
      name         = var.shared_storage.persistent_volume_claim["name"],
      access_modes = var.shared_storage.persistent_volume_claim["access_modes"],
      size         = var.shared_storage.persistent_volume_claim["size"],
    }
  }
}

# ArmoniK components
module "armonik" {
  source     = "./armonik"
  namespace  = var.namespace
  depends_on = [module.storage]

  control_plane = {
    replicas          = var.control_plane.replicas,
    image             = "${var.control_plane.image}:${var.control_plane.tag}"
    image_pull_policy = var.control_plane.image_pull_policy,
    port              = var.control_plane.port,
    storage_services  = {
      object_storage         = {
        type = "MongoDB",
        url  = module.storage.table_storage.spec.0.cluster_ip,
        port = module.storage.table_storage.spec.0.port.0.port
      },
      table_storage          = {
        type = "MongoDB",
        url  = module.storage.table_storage.spec.0.cluster_ip,
        port = module.storage.table_storage.spec.0.port.0.port
      },
      queue_storage          = {
        type = "MongoDB",
        url  = module.storage.table_storage.spec.0.cluster_ip,
        port = module.storage.table_storage.spec.0.port.0.port
      },
      lease_provider_storage = {
        type = "MongoDB",
        url  = module.storage.table_storage.spec.0.cluster_ip,
        port = module.storage.table_storage.spec.0.port.0.port
      },
      shared_storage         = module.storage.shared_storage_claim
    }
  }
}