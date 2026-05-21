resource "random_password" "dev_grouper_postgresql_admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "prod_grouper_postgresql_admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "grouper_aks_s2s_onprem_shared_key" {
  count = var.enable_grouper_aks_s2s_vpn ? 1 : 0

  length  = 64
  special = false
}
