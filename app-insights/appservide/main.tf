data "azurerm_resource_group" "rg"{
     for_each = var.appService
     name = each.value["rg_name"]

}

data "azurerm_service_plan" "dataServicePlan"{
  for_each = var.appService
  name = each.value["service_plan_name"]
  resource_group_name = ["service_plan_rg"]
}


resource "azurerm_app_service" "app" {
  for_each = var.appService
  name                = each.value["web_appName"]
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_service_plan.dataServicePlan.location
  app_service_plan_id     = data.azurerm_service_plan.dataServicePlan.id
client_cert_enabled          = true
 logs {
               detailed_error_messages_enabled = true
            failed_request_tracing_enabled = true
 }
 storage_account {
                name        = "test_name"
                type        = "AzureFiles"
                share_name  = "test_share"
                account_name = "your_account_name"
                access_key  = "your_access_key"
                }
  app_settings = {


  }

  dynamic "site_config"{
    for_each = each.value["site_config"] != null ? each.value["site_config"] : {}
    content {
      always_on = site_config.value["always_on"]
      health_check_path = "/health" 
      ftps_state = "FtpsOnly"
      http2_enabled = site_config.value["http2_enabled"]
     dynamic "application_stack"{
      for_each = site_config.value["application_stack"] != null ? site_config.value["application_stack"] : {}
      content {
        current_stack  = application_stack.value["current_stack"]
        dotnet_version = application_stack.value["dotnet_version"]
      }
     }
    }
  }
}


resource "azurerm_app_service_source_control" "example" {
  for_each = var.simple_auth_enabled && length(var.appService) > 0 ? var.appService : {}

  app_service_name    = each.value.name
  resource_group_name = azurerm_resource_group.example.name

  repo_url           = each.value.git_repo_url
  branch             = each.value.git_branch
  manual_integration = true
}
