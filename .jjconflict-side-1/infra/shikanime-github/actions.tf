resource "github_actions_secret" "cachix_auth_token" {
  for_each        = var.repositories
  repository      = each.value
  secret_name     = "CACHIX_AUTH_TOKEN"
  plaintext_value = var.cachix.auth_token
}

resource "github_actions_secret" "gpg_passphrase" {
  for_each        = var.repositories
  repository      = each.value
  secret_name     = "GPG_PASSPHRASE"
  plaintext_value = var.operator.gpg_passphrase
}

resource "github_actions_secret" "gpg_private_key" {
  for_each        = var.repositories
  repository      = each.value
  secret_name     = "GPG_PRIVATE_KEY"
  plaintext_value = var.operator.gpg_private_key
}

resource "github_actions_secret" "operator_private_key" {
  for_each        = var.repositories
  repository      = each.value
  secret_name     = "OPERATOR_PRIVATE_KEY"
  plaintext_value = var.operator.ssh_private_key
}

resource "github_actions_variable" "operator" {
  for_each      = var.repositories
  repository    = each.value
  variable_name = "OPERATOR_APP_ID"
  value         = var.apps.operator
}

resource "github_actions_secret" "wakabox_github_token" {
  repository      = var.repositories.shikanime
  secret_name     = "WAKABOX_GITHUB_TOKEN"
  plaintext_value = var.wakabox.github_token
}

resource "github_actions_secret" "wakatime_api_key" {
  repository      = var.repositories.shikanime
  secret_name     = "WAKATIME_API_KEY"
  plaintext_value = var.wakabox.wakatime_api_key
}
