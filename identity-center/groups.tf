# Groups only. Users are created in the Identity Center console, or by a
# later process, so this state never holds a person's name or email.

resource "aws_identitystore_group" "this" {
  for_each = var.create_groups ? toset(keys(var.assignments)) : toset([])

  identity_store_id = local.identity_store_id
  display_name      = each.value
  description       = "Foundation group for permission set assignments."
}

data "aws_identitystore_group" "this" {
  for_each = var.create_groups ? toset([]) : toset(keys(var.assignments))

  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value
    }
  }
}
