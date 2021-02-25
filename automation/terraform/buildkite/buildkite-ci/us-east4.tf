locals {
  east4_compute_topology = {
    small = {
      agent = {
        tags  = "size=small"
        token = data.aws_secretsmanager_secret_version.buildkite_agent_token.secret_string
      }
      resources = {
        requests = {
          cpu    = "1"
          memory = "1G"
        }
        limits = {
          cpu    = "2"
          memory = "2G"
        }
      }
      replicaCount = 6
    }

    medium = {
      agent = {
        tags  = "size=medium"
        token = data.aws_secretsmanager_secret_version.buildkite_agent_token.secret_string
      }
      resources = {
        requests = {
          cpu    = "2"
          memory = "2G"
        }
        limits = {
          cpu    = "4"
          memory = "4G"
        }
      }
      replicaCount = 12
    }

    large = {
      agent = {
        tags  = "size=large"
        token = data.aws_secretsmanager_secret_version.buildkite_agent_token.secret_string
      }
      resources = {
        requests = {
          cpu    = "4"
          memory = "4G"
        }
        limits = {
          cpu    = "8"
          memory = "8G"
          ephemeral-storage = "100Gi"
        }
      }
      replicaCount = 6
    }

    xlarge = {
      agent = {
        tags  = "size=xlarge"
        token = data.aws_secretsmanager_secret_version.buildkite_agent_token.secret_string
      }
      resources = {
        requests = {
          cpu    = "8"
          memory = "8G"
        }
        limits = {
          cpu    = "15.5"
          memory = "16G"
          ephemeral-storage = "100Gi"
        }
      }
      replicaCount = 15
    }
  }
}

module "buildkite-east4-compute" {
  source = "../../modules/kubernetes/buildkite-agent"

  k8s_context             = "gke_o1labs-192920_us-east4_buildkite-infra-east4"
  cluster_name            = "gke-east4"
  cluster_namespace       = local.project_namespace

  google_app_credentials  = var.google_credentials

  agent_vcs_privkey       = var.agent_vcs_privkey
  agent_topology          = local.east4_compute_topology
}
