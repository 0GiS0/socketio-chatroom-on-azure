### Providers ###
provider "azurerm" {
  features {}
}

#Random name
resource "random_pet" "service" {}

#Resource Group
resource "azurerm_resource_group" "rg" {
  name     = random_pet.service.id
  location = var.location
}

#Redis Cache
resource "azurerm_redis_cache" "cache" {
  name                = random_pet.service.id
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = true
  minimum_tls_version = "1.2"

  redis_configuration {
  }
}


#Application Insights
resource "azurerm_application_insights" "appinsights" {
  name                = random_pet.service.id
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}


#App Service Plan
resource "azurerm_app_service_plan" "appserviceplan" {
  name                = random_pet.service.id
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier     = "Standard"
    size     = "S1"
    capacity = 1
  }
}

#Web App
resource "azurerm_app_service" "webapp" {
  name                    = random_pet.service.id
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  app_service_plan_id     = azurerm_app_service_plan.appserviceplan.id
  client_affinity_enabled = true

  site_config {
    websockets_enabled = true
    linux_fx_version = "NODE|12.x"
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION"   = "~14"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = true
    # "DEBUG"                          = "*" #DEBUG socket.io
    "REDIS_HOSTNAME"                             = azurerm_redis_cache.cache.hostname
    "REDIS_KEY"                                  = azurerm_redis_cache.cache.primary_access_key
    "REDIS_PORT"                                 = azurerm_redis_cache.cache.port
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = azurerm_application_insights.appinsights.instrumentation_key
    "APPLICATIONINSIGHTSAGENT_EXTENSION_ENABLED" = true
    "WEBSITE_HTTPLOGGING_RETENTION_DAYS"         = "7"
  }
}
