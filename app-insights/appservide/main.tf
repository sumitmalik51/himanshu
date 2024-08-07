data "azurerm_resource_group" "rg"{
     for_each = var.appService
     name = each.value["rg_name"]

}

data "azurerm_service_plan" "dataServicePlan"{
  for_each = var.appService
  name = each.value["service_plan_name"]
  resource_group_name = ["service_plan_rg"]
}


resource "azurerm_windows_web_app" "app" {
  for_each = var.appService
  name                = each.value["web_appName"]
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_service_plan.dataServicePlan.location
  service_plan_id     = data.azurerm_service_plan.dataServicePlan.id

  app_settings = {


  }

  dynamic "site_config"{
    for_each = each.value["site_config"] != null ? each.value["site_config"] : {}
    content {
      always_on = site_config.value["always_on"]
      ftps_state = site_config.value["ftps_state"]
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
