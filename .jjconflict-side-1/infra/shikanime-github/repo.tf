data "github_repository" "repo" {
  for_each = var.repositories
  name     = each.value
}

resource "github_repository_ruleset" "main" {
  for_each = {
    for k, v in var.repositories :
    k => v if !data.github_repository.repo[k].private
  }
  name        = "Main branch protections"
  repository  = each.value
  target      = "branch"
  enforcement = "active"
  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }
  rules {
    required_linear_history = true
    required_signatures     = true
  }
}

resource "github_repository_ruleset" "landing" {
  for_each = {
    for k, v in var.repositories :
    k => v if !data.github_repository.repo[k].private
  }
  name        = "Landing protections"
  repository  = each.value
  target      = "branch"
  enforcement = "active"
  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }
  bypass_actors {
    actor_id    = 2
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }
  bypass_actors {
    actor_id    = var.apps.operator
    actor_type  = "Integration"
    bypass_mode = "always"
  }
  rules {
    pull_request {
      require_code_owner_review         = true
      required_review_thread_resolution = true
    }
    required_status_checks {
      required_check {
        context        = "check"
        integration_id = var.apps.github_actions
      }
      strict_required_status_checks_policy = true
    }
  }
}
