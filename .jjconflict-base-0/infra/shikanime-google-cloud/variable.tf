variable "name" {
  type        = string
  description = "The name for the project"
}

variable "org" {
  type        = string
  description = "The organization ID"
}

variable "billing_account" {
  type        = string
  description = "The ID of the billing account to associate this project with"
}

variable "location" {
  type        = string
  description = "The location for the resources"
}

variable "enabled_apis" {
  type        = list(string)
  description = "List of APIs to enable"
}

variable "members" {
  type = object({
    owner = list(string)
    cloud = list(string)
  })
  description = "List of members to grant roles"
}

variable "terraform_project" {
  type        = string
  description = "The HCP project ID"
}

variable "terraform_organization" {
  type        = string
  description = "The HCP organization ID"
}
