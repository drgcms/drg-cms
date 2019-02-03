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
module DrgcmsFormFields

###########################################################################
# Implementation of journal_diff DRG CMS form field. journal_diff field is used to 
# show differences between two fields in DcJournal collection.
# 
# ===Form options:
# * +name:+ field name (required)
# * +type:+ journal_diff (required)
# 
# Form example:
#    10:
#      name: diff
#      type: journal_diff
#      html:
#        size: 100x25
###########################################################################
class JournalDiff < DrgcmsField

###########################################################################
# Render journal_diff field html code
###########################################################################
def render 
  @yaml['name'] = 'old' if @record[@yaml['name']].nil?
  @html << '<div class="dc-journal">'
  JSON.parse(@record[@yaml['name']]).each do |k,v|
    old_value = v.class == Array ? v[0] : v
    new_value = v.class == Array ? v[1] : v
    @html << "<div style='background-color: #eee;'>#{@parent.check_box('select', k)} #{k}</div>
              <div style='background-color: #fcc;'>-<br>#{old_value}</div>
              <div style='background-color: #cfc;'>+<br>#{new_value}</div><br>"
  end
  @html << '</div>'
  self
end
end

end
