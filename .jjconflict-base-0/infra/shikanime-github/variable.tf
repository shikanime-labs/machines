variable "apps" {
  type = object({
    github_actions = number
    operator       = number
  })
  description = "Application names"
  default = {
    github_actions = 15368
    operator       = 1095999
  }
}

variable "cachix" {
  type = object({
    auth_token = string
  })
  description = "Cachix configuration secrets"
  sensitive   = true
}

variable "operator" {
  type = object({
    gpg_passphrase  = string
    gpg_private_key = string
    ssh_private_key = string
  })
  description = "Operator configuration secrets"
  sensitive   = true
}

variable "repositories" {
  type = object({
    algorithm        = string
    curriculum-vitae = string
    features         = string
    manifests        = string
    myawesomelist    = string
    niximgs          = string
    shikanime        = string
  })
  description = "GitHub repositories"
  default = {
    algorithm        = "algorithm"
    curriculum-vitae = "curriculum-vitae"
    features         = "features"
    manifests        = "manifests"
    myawesomelist    = "myawesomelist"
    niximgs          = "niximgs"
    shikanime        = "shikanime"
  }
}

variable "wakabox" {
  type = object({
    github_token     = string
    wakatime_api_key = string
  })
  description = "Wakabox configuration secrets"
  sensitive   = true
}
