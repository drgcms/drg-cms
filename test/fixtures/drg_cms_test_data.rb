##################################################################
# Fill database with test data
##################################################################
def drg_cms_test_data_fill
  # Roles
  sa_role    = DcPolicyRole.create!(name: 'superadmin', system_name: 'superadmin')
  guest_role = DcPolicyRole.create!(name: 'guest', system_name: 'guest')
  admin_role = DcPolicyRole.create!(name: 'Administrators', system_name: 'admin')

  # collection Permissions
  default_permission = DcPermission.create!(table_name: 'Default permission',is_default: true)
  rule1 = DcPolicyRule.new(dc_policy_role: sa_role, permission: 128)
  rule2 = DcPolicyRule.new(dc_policy_role: guest_role, permission: 0)
  rule3 = DcPolicyRule.new(dc_policy_role: admin_role, permission: 64)
  default_permission.dc_policy_rules << rule1
  default_permission.dc_policy_rules << rule2
  default_permission.dc_policy_rules << rule3
  # dc_memory
  dc_memory_permission = DcPermission.create!(table_name: 'dc_memory')
  rule1 = DcPolicyRule.new(dc_policy_role: guest_role, permission: 8)
  dc_memory_permission.dc_policy_rules << rule1

  # SITE
  site = DcSite.create!(
    name: 'www.mysite.com',
    homepage_link: "home",
    menu_class: "DcSimpleMenu",
    menu_name: "site-menu",
    page_class: "DcPage",
    page_table: "dc_page",
    files_directory: "files",
    settings: "ckeditor:
      config_file: /files/ck_config.js
      css_file: /files/ck_css.css",
    site_layout: "content")

  default_policy = DcPolicy.new(
    description: 'Default policy',
    is_default: true,
    message: 'Access denied.',
    name: 'Default policy')
  site.dc_policies << default_policy

  rule2 = DcPolicyRule.new(dc_policy_role: admin_role, permission: 2)
  rule3 = DcPolicyRule.new(dc_policy_role: guest_role, permission: 1)
  default_policy.dc_policy_rules << rule2
  default_policy.dc_policy_rules << rule3

  site.save

  # TEST site
  testsite = DcSite.create!(name: 'test', alias_for: "www.mysite.com")

  # Users
  rems = DcUser.new(
    username: 'admin',
    name: 'Admin User',
    password_digest: '$2a$10$ifVfdEeCCetvUDl1n2JgCuTPdyyLyl6tXjEX5YlKJjzWErN4lzBkC')
  rems.save
  role1 = DcUserRole.new(dc_policy_role: admin_role, active: true)
  rems.dc_user_roles << role1

  guest = DcUser.new(
    username: 'guest',
    name: 'Guest User',
    password_digest: '$2a$10$ifVfdEeCCetvUDl1n2JgCuTPdyyLyl6tXjEX5YlKJjzWErN4lzBkC')
  guest.save
end

##################################################################
# Delete test data
##################################################################
def drg_cms_test_data_delete
  DcUser.all.delete
  DcSite.all.delete
  DcPermission.all.delete
  DcPolicyRole.all.delete
end

##################################################################
# Load test data
##################################################################
def drg_cms_test_data_load
  p 'load'
  drg_cms_test_data_delete
  drg_cms_test_data_fill
end
