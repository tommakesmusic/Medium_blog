A public repository for code from posts on Medium.

This is for the post:

## Creating an Automation Account with a User-assigned Managed Identity:
* https://medium.com/@thomaswatsonv1/deploying-an-automation-account-with-a-user-assigned-managed-identity-709424d6cdfe
* https://medium.com/@thomaswatsonv1/using-user-assigned-managed-identities-in-azure-automation-runbooks-94000904e8b0
* https://medium.com/@thomaswatsonv1/creating-a-custom-role-for-an-azure-managed-identity-de861e06a8da

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 2.65 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 2.65 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_automation_job_schedule.runbook-schedule-VM-Start](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) | resource |
| [azurerm_automation_job_schedule.runbook-schedule-VM-Stop](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) | resource |
| [azurerm_automation_module.Azure-MI-Automation-module](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_module) | resource |
| [azurerm_automation_runbook.test-VM-runbook](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook) | resource |
| [azurerm_automation_schedule.test-VM-Start-schedule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | resource |
| [azurerm_automation_schedule.test-VM-Stop-schedule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) | resource |
| [azurerm_resource_group_template_deployment.ARMdeploy-automation-acct](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) | resource |
| [azurerm_role_assignment.test-mi-role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.automation-account-managed-id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_client_config.config](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment terraform is creating resources for. | `string` | `"-test"` | no |
| <a name="input_virtual-machine"></a> [virtual-machine](#input\_virtual-machine) | Name of VM to control | `string` | `"test-VM"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_new_managed_id"></a> [new\_managed\_id](#output\_new\_managed\_id) | If needed, we can output our managed ID....id |
