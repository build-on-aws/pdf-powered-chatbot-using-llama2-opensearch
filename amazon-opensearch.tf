terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default     = "us-east-1"
}

variable "collection_name" {
  default     = "pdf-source-docs"
}

resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = "example-encryption-policy"
  type        = "encryption"
  description = "encryption policy for ${var.collection_name}"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.collection_name}"
        ],
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_collection" "collection" {
  name       = var.collection_name
  depends_on = [aws_opensearchserverless_security_policy.encryption_policy]
  type = "VECTORSEARCH"
}

resource "aws_opensearchserverless_security_policy" "network_policy" {
  name        = "${var.collection_name}-policy"
  type        = "network"
  description = "public access for dashboard, VPC access for collection endpoint"
  policy = jsonencode([
    {
      Description = "VPC access for collection endpoint",
      Rules = [
        {
          ResourceType = "collection",
          Resource = [
            "collection/${var.collection_name}"
          ]
        }
      ],
      AllowFromPublic = true
    },
    {
      Description = "Public access for dashboards",
      Rules = [
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${var.collection_name}"
          ]
        }
      ],
      AllowFromPublic = true
    }
  ])
}

data "aws_caller_identity" "current" {}

resource "aws_opensearchserverless_access_policy" "data_access_policy" {
  name        = "${var.collection_name}-policy"
  type        = "data"
  description = "allow index and collection access"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index",
          Resource = [
            "index/${var.collection_name}/*"
          ],
          Permission = [
            "aoss:*"
          ]
        },
        {
          ResourceType = "collection",
          Resource = [
            "collection/${var.collection_name}"
          ],
          Permission = [
            "aoss:*"
          ]
        }
      ],
      Principal = [
        data.aws_caller_identity.current.arn
      ]
    }
  ])
}

output "collection_enpdoint" {
  value = aws_opensearchserverless_collection.collection.collection_endpoint
}
