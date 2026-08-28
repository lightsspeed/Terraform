# ==============================================================================
# PROVIDER CONFIGURATION
# This file declares:
#   1. The Terraform version constraints for the AWS provider plugin
#   2. The default AWS provider pointed at the primary deployment region
#
# A second provider alias ("replica") for Cross-Region Replication is declared
# in replication.tf so it stays co-located with the replication resources.
# ==============================================================================

terraform {
  required_providers {
    # AWS provider sourced from the official HashiCorp registry.
    # Pinned to exactly 6.0.0 — update intentionally when upgrading.
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

# ------------------------------------------------------------------------------
# DEFAULT AWS PROVIDER
# All resources without an explicit "provider" argument use this block.
# Region is driven by the var.region variable (default: us-east-1).
# ------------------------------------------------------------------------------
provider "aws" {
  region = var.region
}
