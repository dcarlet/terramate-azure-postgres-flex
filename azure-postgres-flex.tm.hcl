# This file is part of Terramate Configuration.
# Terramate is an orchestrator and code generator for Terraform.
# Please see https://github.com/mineiros_io/terramate for more information.
#
# To generate/update Terraform code within the stacks
# run `terramate generate` from root directory of the repository.
##############################################################################
# Import our globals
# import {
#     source = "../system_config/system_config.tm.hcl"
# }
##############################################################################
# Defaults for each service account that can be overwritten in stacks below
# Use this if you need to specify a default value that needs to inherit from global variables.
#  Otherwise, just define it directly in variables.tf for your module.
globals {
  # The default name of a Postgres Flexible Server instance is: $workspace_name_abv_$stack.path.basename_pg_$global.env, ex:
  #     cp_dashboard_pg_dev
    service_name = "${terramate.stack.path.basename}"
    pg_server_name = "${global.workspace_name_abv}_${service_name_pg}_${global.environment}"
    project_keyvault = global.workspace_keyvault_name # By default, we'll put the secrets into OUR key vault.
    default_availability_zone = 1
    storage_size_mb = 32768
    pg_ver = 14
    admin_username = "${service_name_pg}_${global.environment}_adm"
    sku = "GP_Standard_D2s_v3"
    backup_rentention_days = 14
    postgres_db_name = "${service_name_pg}_${global.environment}_db"
    extensions_list = "PG_TRGM,BTREE_GIST"
}

##############################################################################
# Generate '_terramate_generated_cloud_run.tf' in each stack
# All globals will be replaced with the final value that is known by the stack
# Any terraform code can be defined within the content block
generate_hcl "_terramate_generated_azure_postgres_flexible_server.tf" {
  content {

    # We are invoking our local wrapper to the module
    # to also demonstrate terramate orchestration capabilities
    module "azure_postgres_flex" {
        source = "../modules/azure-postgres-flex"

        target_rg = global.default_rg
        target_vnet = global.common_vnet_name
        target_vnet_rg = global.net_rgp_name
        flexible_server_subnet = global.cmn_postgres_snet_name
        tags = merge(global.tags, global.module_tags, global.service_tags)
        project_keyvault = global.project_keyvault
        pg_server_name = global.pg_server_name
        pg_version = global.pg_ver
        zone = global.default_availability_zone
        storage_mb = global.storage_size_mb
        sku = global.sku
        backup_rentention_days = global.backup_rentention_days
        postgres_db_name = global.postgres_db_name
        extensions_list = global.extensions_list

    }

    # An output to show the cloud run url after a successful terraform apply
    output "fqdn" {
      description = "URL of ${global.pg_server_name}"
      value       = module.azure_postgres_flex.fqdn
    }
  }
}

