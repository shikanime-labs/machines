output "projects" {
  value = {
    studio = {
      name            = "shikanime-studio"
      org             = ""
      billing_account = "018C2E-353598-F0F3A5"
      location        = "europe-west1"
      enabled_apis = [
        "artifactregistry.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "compute.googleapis.com",
        "iam.googleapis.com",
        "iamcredentials.googleapis.com",
        "run.googleapis.com",
        "serviceusage.googleapis.com",
      ]
      members = {
        owner = ["user:shikalegend@gmail.com"]
        cloud = ["group:shikanime-studio-cloud@googlegroups.com"]
      }
      terraform_project      = "prj-NCaGDhtLX1Qaox7L"
      terraform_organization = "org-ZuQrk9oiA78Cy3Ls"
    }
    studio-labs = {
      name            = "shikanime-studio-labs"
      org             = ""
      billing_account = "018C2E-353598-F0F3A5"
      location        = "europe-west1"
      enabled_apis = [
        "aiplatform.googleapis.com",
        "artifactregistry.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "compute.googleapis.com",
        "datacatalog.googleapis.com",
        "dataflow.googleapis.com",
        "dataform.googleapis.com",
        "datalineage.googleapis.com",
        "iam.googleapis.com",
        "iamcredentials.googleapis.com",
        "notebooks.googleapis.com",
        "run.googleapis.com",
        "serviceusage.googleapis.com",
        "visionai.googleapis.com",
      ]
      members = {
        owner = ["user:shikalegend@gmail.com"]
        cloud = ["group:shikanime-studio-cloud@googlegroups.com"]
      }
      terraform_project      = "prj-qGuaiqVzKAr318n6"
      terraform_organization = "org-ZuQrk9oiA78Cy3Ls"
    }
  }
}
