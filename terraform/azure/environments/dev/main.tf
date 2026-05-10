
terraform{
	required_version = ">=1.5"

	required_providers {
		azurerm = {source = "hashicorp/azurerm"
			version ="~>3.0" }

	}


}

provider "azurerm"{
	features {}
	subscription_id = var.subscription_id

}


# ── MODULE 1: VNET ────────────────────────────────────────────
module "vnet" {
  source = "../../modules/vnet"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
}


# ── MODULE 2: DATABASE ────────────────────────────────────────
module "database" {
  source = "../../modules/database"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
  db_password         = var.db_password
  subnet_id           = module.vnet.db_subnet_id
}

# ── MODULE 3: REGISTRY ────────────────────────────────────────
module "registry" {
  source = "../../modules/registry"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
}

# ── MODULE 4: CONTAINER APPS ──────────────────────────────────
module "container_apps" {
  source = "../../modules/container-apps"

  project_name                = var.project_name
  environment                 = var.environment
  resource_group_name         = var.resource_group_name
  location                    = var.location
  subnet_id                   = module.vnet.container_subnet_id
  registry_login_server       = module.registry.login_server
  registry_admin_username     = module.registry.admin_username
  registry_admin_password     = module.registry.admin_password
  database_url                = module.database.database_url
}

