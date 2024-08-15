data "azurerm_resource_group" "rg"{
     for_each = var.appInsights
     name = each.value["rg_name"]

}

resource "azurerm_user_assigned_identity" "userAssignedIdentityProvision" {
  for_each            = var.managed_identities
  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
