# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-logicapp-demo"
  location = "East US"
}

# Storage Account (required for Logic Apps)
resource "azurerm_storage_account" "storage" {
  name                     = "logicappstorageacc"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Logic App Workflow
resource "azurerm_logic_app_workflow" "logicapp" {
  name                = "logicapp-alert-demo"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  definition = jsonencode({
    "$schema" = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowDefinition.json#"
    "actions" = {
      "Send_an_email" = {
        "type" = "ApiConnection"
        "inputs" = {
          "method"       = "post"
          "body"         = {
            "message" = "Alert: A condition has been met."
            "subject" = "Automated Alert"
            "to"      = "<RECIPIENT_EMAIL>"
          }
          "host" = {
            "connection" = {
              "name" = "@parameters('$connections')['office365']['connectionId']"
            }
          }
          "path" = "/v2/Mail"
        }
      }
    }
    "triggers" = {
      "When_a_resource_is_updated" = {
        "type" = "Http"
        "recurrence" = {
          "frequency" = "Minute"
          "interval"  = 5
        }
        "inputs" = {
          "method" = "GET"
          "uri"    = "https://<API_ENDPOINT_TO_CHECK_CONDITION>"
        }
      }
    }
  })

  integration_service_environment_id = azurerm_integration_service_environment.example.id
}

# Logic App Integration with Office 365 (or other connectors)
resource "azurerm_logic_app_trigger_http_request" "http_trigger" {
  name                = "trigger-http-request"
  logic_app_id        = azurerm_logic_app_workflow.logicapp.id
  methods             = ["GET", "POST"]
}

# Azure Automation Account (optional if needed)
resource "azurerm_automation_account" "automation" {
  name                = "automationaccountdemo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"
}

# Alerts Configuration (optional)
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "cpu-high-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_logic_app_workflow.logicapp.id]
  description         = "High CPU Usage Alert"
  severity            = 3

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.example.id
  }
}

# Action Group (optional for alert notification)
resource "azurerm_monitor_action_group" "example" {
  name                = "action-group-demo"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "actionGroup"

  email_receiver {
    name          = "admin"
    email_address = "<RECIPIENT_EMAIL>"
  }
}
