#--
# Copyright (c) 2024+ Damjan Rems
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

################################################################################
# Controls for DcSetup edit form.
################################################################################
module DcSetupControl

################################################################################
# Update edit form. Admin sees everything while user sees only setup fields.
################################################################################
def dc_update_form
  return unless params[:id]

  record = if BSON::ObjectId.legal?(params[:id])
             DcSetup.find(params[:id])
           else
             DcSetup.find_by(name: params[:id])
           end

  unless dc_user_has_role('admin')
    @form['form'].delete('tabs')
    @form['readonly'] = true unless record.editors.include?(session[:user_id])
  end

  form = YAML.load(record.form) rescue nil
  if form.present?
    @form['form']['tabs'] ||= {}
    @form['form']['tabs'].merge!(form)
  end
end

end
