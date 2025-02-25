module "default_images" {
  source = "../generated/infra-modules/utils/default-images"

  armonik_versions = var.armonik_versions
  armonik_images   = var.armonik_images
  image_tags       = var.image_tags
}

locals {
  default_tags = module.default_images.image_tags
}
