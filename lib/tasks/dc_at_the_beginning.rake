#########################################################################
#
#########################################################################
def ok_to_start
  p ''
#  DcPermission.all.delete
#  DcPolicyRole.all.delete
#  DcUser.all.delete
  if DcPermission.all.size > 0
    p 'DcPermission (Permissions) collection is not empty! Aborting.'
    return false
  end
  if DcPolicyRole.all.size > 0
    p 'DcUserRole (User roles) collection is not empty! Aborting.'
    return false
  end
  if DcUser.all.size > 0
    p 'DcUser (Users) collection is not empty! Aborting.'
    return false
  end
  true
end

#########################################################################
#
#########################################################################
def read_input(message, default='')
  print "#{message} "
  response = STDIN.gets.chomp
  response.blank? ? default : response
 end

########################################################################
#
########################################################################
def create_superadmin
  username = read_input('Enter username for superadmin role:')
  return p 'Username should be at least 6 character long' unless username.size >=6
#
  password1 = read_input("Enter password for #{username} user :")
  return p 'Password should be at least 8 character long' unless password1.size >=8
#
  password2 = read_input("Please repeat password for #{username} user :")
  return p 'Passwords are not equal' unless password2 == password1
#  
# Guest role first
  role = DcPolicyRole.new
  role.name = 'guest'
  role.system_name = 'guest'
  role.save
# Superadmin role
  sa = DcPolicyRole.new
  sa.name = 'superadmin'
  sa.system_name = 'superadmin'
  sa.save
# Superadmin user
  usr = DcUser.new
  usr.username    = username
  usr.password    = password1
  usr.password_confirmation = password2
  usr.first_name  = 'superadmin'
  usr.save
# user role 
#  r = usr.dc_user_roles.new
#  r.dc_policy_role_id = role._id
#  r.save
  r = DcUserRole.new
  r.dc_policy_role_id = sa._id
  usr.dc_user_roles << r
# cmsedit permission
  permission = DcPermission.new
  permission.table_name = 'Default permission'
  permission.is_default = true
  permission.save
# 
  r = DcPolicyRule.new
  r.dc_policy_role_id = sa._id
  r.permission = DcPermission::SUPERADMIN
  permission.dc_policy_rules << r
# create login poll
  poll = DcPoll.new
  poll.name = 'login'
  poll.display = 'td'
  poll.operation = 'link'
  poll.parameters = '/dc_common/process_login'
  poll.title = 'Autocreated login form'
  poll.save
#
  i = poll.dc_poll_items.new
  i.name = 'username'
  i.size = 15
  i.text = 'Username'
  i.type = 'text_field'
  i.save
#  
  i = poll.dc_poll_items.new
  i.name = 'password'
  i.size = 15
  i.text = 'Password'
  i.type = 'password_field'
  i.save
#
  i = poll.dc_poll_items.new
  i.name = 'send'
  i.text = 'Login'
  i.type = 'submit_tag'
  i.save
#
  p "Superadmin user created. Please remember login data #{username}/#{password1}"
end  

########################################################################
# Initial database seed
########################################################################
def seed
  if DcSite.all.size > 0
    p 'DcSite (Sites) collection is not empty! Aborting.'
    return 
  end
#
  if (sa = DcPolicyRole.find_by(system_name: 'superadmin')).nil?
    p 'superadmin role not defined! Aborting.'
    return 
  end
#
  if (guest = DcPolicyRole.find_by(system_name: 'guest')).nil?
    p 'guest role not defined! Aborting.'
    return 
  end
# Site document
  site = DcSite.new(
    name: 'www.mysite.com',
    homepage_link: "home",
    menu_class: "DcSimpleMenu",
    menu_name: "site-menu",
    page_class: "DcPage",
    page_table: "dc_page",
    files_directory: "files",    
    settings: "ckeditor:\n config_file: /files/ck_config.js\n css_file: /files/ck_css.css\n",
    site_layout: "content")
  site.save
#
  policy = DcPolicy.new(
    description: "Default policy",
    is_default: true,
    message: "Access denied.",
    name: "Default policy")
  site.dc_policies << policy
#
  rule = DcPolicyRule.new( dc_policy_role_id: sa._id, permission: 4)
  policy << rule
  rule = DcPolicyRule.new( dc_policy_role_id: guest._id, permission: 1)
  policy << rule
# Design document  
  design = DcDesign.new(name: 'simple',description: 'Simple page')
  design.body =<<EOT
<div id="site">
  <div id="site-top">
    <a href="/">SITE LOGO</a>
  </div>
  <div id="site-menu" 
    <%= dc_render(:dc_simple_menu, method: 'as_table') %>\
  </div> 
  <div id="site-main">
   <%= dc_render(:dc_page) %>
  </div>
  <div id="site-bottom">
   <%= dc_render(:dc_piece, name: 'site-bottom') %>
  </div>
</div>
EOT
  design.save
#
  page = DcPage.new(
    subject: 'Home page',
    subject_link: 'home',
    dc_design_id: design._id,
  )
end

#########################################################################
#
#########################################################################
namespace :drg_cms do
  desc "At the beginning god created superadmin"
  task :at_the_beginning => :environment do
    if ok_to_start
      create_superadmin
    end
  end

  desc "Seed initial data"
  task :seed => :environment do
    seed
  end

end