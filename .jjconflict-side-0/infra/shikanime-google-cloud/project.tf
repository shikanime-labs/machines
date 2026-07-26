module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 15.0"

  name            = var.name
  org_id          = var.org
  billing_account = var.billing_account
  project_sa_name = "project-operator"
  activate_apis   = var.enabled_apis
}