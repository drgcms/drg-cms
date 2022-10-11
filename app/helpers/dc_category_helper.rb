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
  html = '<div id="catagories-as-tree"><ul><li data-id="nil"><span class="mi-o mi-home"></span>'
  data = DcCategory.where(parent: nil).order_by(order: 1).to_a
  html_for_category_tree(html, data)
  (html << '</li></ul></div>' << js_for_category_tree).html_safe
end

private

####################################################################
#
####################################################################
def html_for_category_tree(html, data)
  html << '<ul>'
  data.each do |category|
    icon = category.active ? 'check_box' : 'check_box_outline_blank'
    html << %(<li id="#{category.id}" data-parent="#{category.parent}"><span class="mi-o mi-#{icon} mi-18"></span>#{category.name}\n)
    children = DcCategory.where(parent: category.id).order_by(order: 1).to_a

    html_for_category_tree(html, children) if children.size > 0
    html << '</li>'
  end
  html << '</ul>'
end

####################################################################
#
####################################################################
def js_for_category_tree
  %(<script>
$(function() {
  $("#catagories-as-tree").jstree( {
    core: { themes: { icons: false },
            multiple: false
          },
    plugins: ["types", "contextmenu"],
    contextmenu: {
        items: function ($node) {
            return {
                edit: {
                    label: "<span class='dc-result-submenu'>#{t('drgcms.edit')}</span>",
                    icon: "mi-o mi-edit",
                    action: function (obj) {
                        let id = $('#catagories-as-tree').jstree('get_selected', true)[0].id;
                        let params = "&ids=" + id;
                        location.href = "/cmsedit/" + id + "/edit?t=dc_category&f=dc_category_as_tree" + params;
                    }
                },

                new_child: {
                    label: "<span class='dc-result-submenu'>#{t('drgcms.new')}</span>",
                    icon: "mi-o mi-plus",
                    action: function (obj) {
                        let id = $('#catagories-as-tree').jstree('get_selected', true)[0].id;
                        let params = "&ids=" + id + "&p_parent=" + id;
                        location.href = "/cmsedit/new?t=dc_category&f=dc_category_as_tree" + params
                    }
                },

                delete: {
                    label: "<span class='dc-result-submenu'>#{t('drgcms.delete')}</span>",
                    icon: "mi-o mi-delete",
                    action: function (obj) {
                        if (confirmation_is_cancled("#{t('drgcms.confirm_delete')}") === true) return false;

                        let id = $('#catagories-as-tree').jstree('get_selected', true)[0].id;
                        let id_return = $('#catagories-as-tree').jstree('get_selected', true)[0].data["parent"];

                        $.ajax({
                            url: "/cmsedit/" + id + "?t=dc_category",
                            type: 'DELETE',
                            success: function(data) {
                              let error = data.match("#{I18n.t('drgcms.category_has_subs')}");
                              if (error !== null) {
                                alert(error[0]);
                                params = "?t=dc_category&f=dc_category_as_tree&ids=" + id;
                                location.href = "/cmsedit" + params;
                                return true;
                              }
                            }
                        });

                        let params = "?t=dc_category&f=dc_category_as_tree&ids=" + id_return;
                        location.href = "/cmsedit" + params;
                    }
                },
            }
          },
       },
    });
    $("#catagories-as-tree").jstree(true).select_node("#{params[:ids]}");
});

</script>)
end

end
