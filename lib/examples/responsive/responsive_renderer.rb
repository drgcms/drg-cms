#coding: utf-8
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

########################################################################
#
########################################################################
class ResponsiveRenderer < DcRenderer

########################################################################
# i_move may move between right and main part.
########################################################################
def i_move
  html = '<div id="i-move"><h2>I MOVE WHEN ON PHONE<h2>'
  html << 'Contents'
  html << '</div>'
end

########################################################################
# Roller rolls ads in it's div. With little help of slick javascript library.
########################################################################
def roller
  html = '<div class="sponsors">'
# Ads are saved in home page parts which have 'ads' written in div_id field.
  home = DcPage.find_by(dc_site_id: @parent.dc_get_site._id, subject_link: 'home')
  ads = home.dc_parts.where(div_id: 'ads')
  ads = ads.and(active: true) unless @parent.dc_edit_mode? # active only
  ads = ads.order_by(order: 1).to_a
  html << 'OUR SPONSORS' if ads.size > 0 or @parent.dc_edit_mode?
  ads.each do |ad|
# Edit link for ad    
    if @parent.dc_edit_mode?
      opts = { controller: 'cmsedit', action: 'edit', formname: 'ad', 
               table: "#{@parent.site.page_table};dc_part", ids: home._id, 
               id: ad._id, title: 'Edit sponsor\'s ad.' }
      html << @parent.dc_link_for_edit(opts)    
    end
    html << "<div>#{@parent.link_to(@parent.image_tag(ad.picture),ad.link, target: '_blank')}</div>"
  end
# Link for new ad
  if @parent.dc_edit_mode?
    opts = { controller: 'cmsedit', action: 'create', formname: 'ad', 
             table: "#{@parent.site.page_table};dc_part", ids: home._id, 
             'dc_part.div_id' => 'ads', title: 'Add new sponsor\'s ad!' }
    html << @parent.dc_link_for_create(opts)    
  end
  html << '</div>' 
  html << @parent.javascript_tag( "$('.sponsors').slick({
          autoplay: true, infinite: true, autoplaySpeed: 2000, speed: 2000, 
          arrows: false});" ) unless @parent.dc_edit_mode?
  html
end

########################################################################
# EU cookies message.
########################################################################
def eu_cookies
  html =<<EOT 
  <div id="cookies-msg">
  Our web site is using cookies in order to ensure best user experience. 
  By visiting our web site you agree to our conditions. 
  <span class="cookies-yes">Close</span> 
  #{@parent.link_to('More information about cookies!','/cookies')}
  </div>
EOT
  html.html_safe
end

########################################################################
# Send mail dialog. Data can also be rendered by Rails render method.
########################################################################
def send_mail
  @parent.render(partial: 'responsive_views/send_email')
end

########################################################################
#
########################################################################
def render_html
  method = @opts[:method] || 'default'
  respond_to?(method) ? send(method) : "#{self.class}. Method #{method} not found!"
end

end
