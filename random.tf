resource "random_string" "stage_acr_suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "random_string" "prod_acr_suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}
