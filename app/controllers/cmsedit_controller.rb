#--
# Copyright (c) 2012+ Damjan Rems
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

########################################################################
# This is main controller for processing actions by DRG forms. It provides 
# CRUD actions for editing MongoDB documents. DRG CMS does not require controller
# to be made for every document model but centers all actions into single 
# controller. Logic required to control data entry is provided within DRG 
# forms which are loaded dynamically for every action.
# 
# Most of data entry controls must therefore be done in document models definitions. 
# And there are controls that cannot be done in document models. Like controls
# which include url parameters or accessing session variables. This is hard to be done
# in model therefore cmsedit_controls had to be invented. cmsedit_controls are
# modules with methods that are injected into cmsedit_controller and act in runtime like 
# they are part of cmsedit_controller. 
# 
# Since Ruby and Rails provide some automagic loading of modules DRG CMS controls must be saved 
# into app/controllers/drgcms_controls folder. Every model can have its own controls file. 
# dc_page model's controls live in dc_page_controls.rb file. If model has embedded document
# its control's would be found in model_embedded_controls.rb. By convention module names
# are declared in camel case, so our dc_page_controls.rb declares DrgcmsControls::DcPageControls module.
# 
# Controls (among other) may contain 7 callback methods.
# These methods are:
# * dc_new_record
# * dc_dup_record
# * dc_before_edit
# * dc_before_save
# * dc_after_save
# * dc_before_delete
# * dc_after_delete
# 
# Methods dc_before_edit, before_save or before_delete may also effect flow of the application. If
# method return false (not nil but FalseClass) normal flow of the program is interrupted and last operation
# is canceled. 
# 
# Second control methods that can be declared in DRG CMS controls are filters for
# viewing and sorting documents. It is often required that dynamic filters are 
# applied to result_set documents. 
# 
#    result_set:
#      filter: current_users_documents
#      
# Example implemented controls method:
# 
#    def current_users_documents
#      if dc_user_can(DcPermission::CAN_READ)
#        dc_page.where(created_by: session[:user_id])
#      else
#        flash[:error] = 'User can not perform this operation!'
#        nil
#      end
#    end
#      
# If filter method returns false user will be presented with flash error.
########################################################################
class CmseditController < CmsController
end

