# ==============================================================================
# INPUT VARIABLES
# Centralised declaration of all configurable parameters for this lab.
# Values can be overridden via:
#   - terraform.tfvars file
#   - -var="key=value" CLI flag
#   - TF_VAR_<name> environment variable
# ==============================================================================

# ------------------------------------------------------------------------------
# CORE BUCKET SETTINGS
# ------------------------------------------------------------------------------

# The globally unique name for the primary S3 bucket.
# S3 bucket names must be lowercase, 3-63 characters, and DNS-compliant.
# No default — must be explicitly supplied at plan/apply time.
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

# AWS region where the primary bucket (and most resources) will be created.
# The default maps to US East (N. Virginia) — the most commonly used region.
variable "region" {
  description = "The AWS region where the primary S3 bucket will be deployed"
  type        = string
  default     = "us-east-1"
}

# Map of key/value tags applied to all resources.
# At minimum, an "Environment" key is expected (used in tags blocks).
# Add more keys (e.g., Owner, CostCenter) as needed without changing resource code.
variable "tags" {
  description = "Tags to apply to all resources in this configuration"
  type        = map(string)
  default = {
    Environment = "Dev"
  }
}

# Human-readable description for the bucket — stored as metadata only.
# Not directly attached to the S3 bucket (S3 has no native description field),
# but available for use in descriptions, SSM parameters, or tagging.
variable "description" {
  description = "Description of the S3 bucket (used for documentation purposes)"
  type        = string
  default     = "This is a private S3 bucket"
}

# ------------------------------------------------------------------------------
# CROSS-REGION REPLICATION (CRR) SETTINGS
# ------------------------------------------------------------------------------

# The AWS region where the replica (destination) bucket will be created.
# Must be DIFFERENT from var.region — CRR requires cross-region replication.
# Common DR pairing for us-east-1 is us-west-2.
variable "replication_region" {
  description = "The AWS region for the CRR replica bucket (must differ from var.region)"
  type        = string
  default     = "us-west-2"
}

# Name for the replica bucket. If left blank (""), Terraform auto-generates
# the name as "<bucket_name>-replica" using a conditional in replication.tf.
variable "replica_bucket_name" {
  description = "Name of the CRR destination bucket. Leave empty to auto-generate as '<bucket_name>-replica'"
  type        = string
  default     = ""
}
