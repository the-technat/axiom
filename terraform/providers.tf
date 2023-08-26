provider "openstack" {
  application_credential_secret = var.openstack_token
  application_credential_id     = "4e7a622b013b49f7875628b3a8d2543d"
  auth_url                      = "https://api.pub1.infomaniak.cloud/identity"
  region                        = "dc3-a"
}

provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = "the-technat.github"
}

provider "akeyless" {
  api_gateway_address = "https://api.akeyless.io"
  api_key_login {
    access_id  = "p-zzvst51rfc6q"
    access_key = var.akeyless_access_key
  }
}
