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


####################################################################
# Helper for editing categories as tree view.
####################################################################
module DcCategoryHelper

####################################################################
#
####################################################################
def categories_as_tree
  html = '<div id="catagories-as-tree">'
  data = DcCategory.where(parent: nil, active: true).order_by(order: 1).to_a
  data_for_tree(html, data)
  (html << '</div>' << js_for_tree).html_safe
end

private

####################################################################
#
####################################################################
def data_for_tree(html, data)
  html << '<ul>'
  data.each do |category|
    p category.name
    html << %(<li data-id="#{category.id}" data-jstree="{enabled}">#{category.name}\n)
    childreen = DcCategory.where(parent: category.id, active: true).order_by(order: 1).to_a

    data_for_tree(html, childreen) if childreen.size > 0
    html << '</li>'
  end
  html << '</ul>'
end

####################################################################
#
####################################################################
def js_for_tree
  %(<script>
$(function() {
  $("#catagories-as-tree").jstree( {
    "checkbox" : {"three_state" : false},
    "core" : { "themes" : { "icons": true } },
    "plugins" : [ "conditionalselect"],
    "conditionalselect" : function (node) { return false; }
    });
});

$(document).ready(function() {
  $('.jstree-icon.jstree-themeicon').on('click', function(e) {
    console.log(e);
    //e.attr("data-id");
  });
});
</script>)
end

end
