# Profile
variable "profile" {
  description = "Profile of AWS credentials to deploy Terraform sources"
  type        = string
  default     = "default"
}

# Region
variable "region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "eu-west-3"
}

# SUFFIX
variable "suffix" {
  description = "To suffix the AWS resources"
  type        = string
  default     = "main"
}


# Aws account id
variable "aws_account_id" {
  description = "AWS account ID where the infrastructure will be deployed"
  type        = string
}

# Kubeconfig path
variable "k8s_config_path" {
  description = "Path of the configuration file of K8s"
  type        = string
  default     = "~/.kube/config"
}

# Kubeconfig context
variable "k8s_config_context" {
  description = "Context of K8s"
  type        = string
  default     = "default"
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for metrics server"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for metrics server"
  type = object({
    image = string
    tag   = string
  })
}

# image pull secrets
variable "image_pull_secrets" {
  description = "image_pull_secrets for metrics server"
  type        = string
}

# Node selector
variable "node_selector" {
  description = "Node selector for metrics server"
  type        = any
}

# Args
variable "args" {
  description = "Arguments for metrics server"
  type        = list(string)
}

# Host network
variable "host_network" {
  description = "Host network for metrics server"
  type        = bool
}

# Repository of helm chart
variable "helm_chart_repository" {
  description = "Path to helm chart repository for metrics server"
  type        = string
}

# Version of helm chart
variable "helm_chart_version" {
  description = "Version of chart helm for metrics server"
  type        = string
}