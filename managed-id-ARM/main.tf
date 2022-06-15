# main.tf terraform

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  # configure the backend if this will be run on a pipeline not local machine
  backend "azurerm" {}

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

### variables and data ###
variable "environment" {
  description = "Environment terraform is creating resources for."
  type        = string
  default     = "-test"
}

variable "virtual-machine" {
  description = "Name of VM to control"
  type        = string
  default     = "test-VM"
}

locals {
  prefix = "sandbox-"

  rg = "${local.prefix}rg" # Use a suitable value for your own resource group

  location = "YOUR-LOCATION" # Use a suitable value for your own location

  automationAccount_name = "${local.prefix}AutomationAccount${var.environment}"

  my_tags = {
    Owner    = "your-name"
    Reason   = "test"
    Lifespan = "temporary"
    Project  = "MI-Auto-test"
  }
}

data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "config" {
}

### resource provisioning code ###

# Create a user-assigned managed identity
resource "azurerm_user_assigned_identity" "automation-account-managed-id" {
  resource_group_name = local.rg
  location            = local.location

  name = "${local.prefix}automation-mi${var.environment}"
  tags = local.my_tags
}

# If needed, we can output our managed ID....id
output "new_managed_id" {
  value = azurerm_user_assigned_identity.automation-account-managed-id.id
}

# Give the user managed identity a role that allows it to do stuff
# You must have permissions to grant the MI the needed role 
resource "azurerm_role_assignment" "test-mi-role" {
  scope                = "YOUR-SCOPE" # I used the resource group
  
  # built-in roles are available here: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
    role_definition_name = "Virtual Machine Contributor" # or
  # role_definition_id = 9980e02c-c2be-4d73-94e8-173b1dc7cf3c

  # role_definition_name = "Reader" # or
  # role_definition_id = acdd72a7-3385-48ef-bd42-f606fba81ae7

  # principal_id is the id of the 'principal' (i.e. the principal_id of the user assigned system managed identity we just created) 
  principal_id         = azurerm_user_assigned_identity.automation-account-managed-id.principal_id
  
}


# Create a resource using an ARM template
# In this case an automation account with a user managed identity

resource "azurerm_resource_group_template_deployment" "ARMdeploy-automation-acct" {
  name                = "${local.prefix}ARMdeploy-Automation-Start"
  resource_group_name = local.rg

  # "Incremental" ADDS the resource to already existing resources. "Complete" destroys all other resources and creates the new one
  deployment_mode     = "Incremental"

  # the parameters below can be found near the top of the ARM file
  parameters_content = jsonencode({
    "automationAccount_name" = {
      value = local.automationAccount_name
    },
    "my_location" = {
      value = local.location
    },
    "userAssigned_identity" = {
      value = azurerm_user_assigned_identity.automation-account-managed-id.id
    }
  })
  # the actual ARM template file we will use
  template_content = file("user-id-template.json")
}

# runbook for VM Start and Stop
resource "azurerm_automation_runbook" "test-VM-runbook" {
  name                    = "Azure-MI-VM-Control"
  location                = local.location
  resource_group_name     = local.rg
  automation_account_name = local.automationAccount_name
  log_verbose             = "true" # Change to false when it works
  log_progress            = "true" # Change to false when it has been tested
  description             = "This is a modified runbook used to start and stop VMs using a managed identity"
  runbook_type            = "PowerShell"
  
  # The Azure API requires a publish_content_link to be supplied even when specifying your own content.
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook
  # So we'll just add our runbook to the repo and link it here
  # Also the runbook must be on a public repo
  publish_content_link {
    uri = "https://raw.githubusercontent.com/tommakesmusic/Medium_blog/main/managed-id-ARM/Azure-MI-VM-Control.ps1"
  }
  depends_on = [
    azurerm_resource_group_template_deployment.ARMdeploy-automation-acct
  ]
}


# For each runbook we may need to add the appropriate powershell modules into the account
# For a managed identity functions we may need to add this one.
resource "azurerm_automation_module" "Azure-MI-Automation-module" {
  name                    = "Az.ManagedServiceIdentity"
  resource_group_name     = local.rg
  automation_account_name = local.automationAccount_name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.ManagedServiceIdentity/0.7.3"
  }
    depends_on = [
    azurerm_resource_group_template_deployment.ARMdeploy-automation-acct
  ]
}


# Create a schedule for our VM Start
resource "azurerm_automation_schedule" "test-VM-Start-schedule" {
  name                    = "${local.prefix}automation-start-schedule"
  resource_group_name     = local.rg
  automation_account_name = local.automationAccount_name
  frequency               = "Hour"
  interval                = 1
  timezone                = "Europe/London"
  # Resource needs to be created at least 5 full minutes before schedule can start
  start_time  = timeadd(timestamp(), "20m") # This creates a start_time twenty minutes after creation for test purposes only 
  description = "This is a schedule to START VM. Deployed via Azure DevOps and Terraform"
  depends_on = [
    azurerm_resource_group_template_deployment.ARMdeploy-automation-acct
  ]
}

# link runbook and schedule together to create a job_schedule
# Due to a bug in the implementation of Runbooks in Azure, the parameter names need to be specified in lowercase only.
# See: "https://github.com/Azure/azure-sdk-for-go/issues/4780" for more information.
resource "azurerm_automation_job_schedule" "runbook-schedule-VM-Start" {
  resource_group_name     = local.rg
  automation_account_name = local.automationAccount_name
  schedule_name           = azurerm_automation_schedule.test-VM-Start-schedule.name
  runbook_name            = azurerm_automation_runbook.test-VM-runbook.name

  # parameters:
  # Most are obvious but
  # action is either stop or start - whichever you want to do to VM

  parameters = {
    mi_principal_id       = azurerm_user_assigned_identity.automation-account-managed-id.principal_id
    vmname                = var.virtual-machine
    resourcegroup         = local.rg
    action                = "Start"
  }
  depends_on = [azurerm_automation_schedule.test-VM-Start-schedule]
}


# Create a schedule for VM Stop
resource "azurerm_automation_schedule" "test-VM-Stop-schedule" {
  name                    = "${local.prefix}automation-stop-schedule"
  resource_group_name     = local.rg
  automation_account_name = local.automationAccount_name
  frequency               = "Hour"
  interval                = 1
  timezone                = "Europe/London"
  # Resource needs to be created at least 5 full minutes before schedule can start
  start_time  = timeadd(timestamp(), "10m") # This creates a start_time ten minutes after creation for test purposes only 
  description = "This is a schedule to STOP VM. Deployed via Azure DevOps and Terraform"
  depends_on = [
    azurerm_resource_group_template_deployment.ARMdeploy-automation-acct
  ]
}

# link runbook and schedule together to create a job_schedule
resource "azurerm_automation_job_schedule" "runbook-schedule-VM-Stop" {
  resource_group_name     = local.rg
  automation_account_name = local.automationAccount_name
  schedule_name           = azurerm_automation_schedule.test-VM-Stop-schedule.name
  runbook_name            = azurerm_automation_runbook.test-VM-runbook.name
  
  # parameters:
  # Most are obvious but
  # action is either stop or start - whichever you want to do to VM

  parameters = {
    mi_principal_id       = azurerm_user_assigned_identity.automation-account-managed-id.principal_id
    vmname                = var.virtual-machine
    resourcegroup         = local.rg
    action                = "Stop"
  }
  depends_on = [azurerm_automation_schedule.test-VM-Stop-schedule]
}
