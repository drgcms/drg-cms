#encoding: utf-8
#--
# Copyright (c) 2014+ Damjan Rems
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

######################################################################
# DrgcmsControls for DcPage model.
######################################################################
module DcPageControl

######################################################################
# Called when new empty record is created
######################################################################
def dc_new_record()
  @record.design_id = params[:design_id] if params[:design_id]
  return unless params[:page_id]
#
  if page = DcPage.find(params[:page_id])
    @record.design_id = page.design_id
    @record.menu      = page.menu
  end
end

######################################################################
# Called just after record is saved to DB.
######################################################################
def dc_after_save()
  if params[:_record] and params[:_record][:_update_menu] == '1'
#    menu_class = dc_get_site.menu_class.classify.constantize
    dc_get_site.menu_klass.update_menu_item_link(@record)
  end
end

end 
