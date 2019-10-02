#--
# Copyright (c) 2012-2013 Damjan Rems
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
# EXPRESS OR IMPLIED, INCLUDING BUTe NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

########################################################################
# Ads renderer. Typically ads renderer is defined in design like this.
#    <div id="ads-on-top">
#       <%= dc_render(:dc_ad, position: 'top') %>
#    </div>
# 
# There can be more than one ad shown on the same position. Therefore Ads can be grouped by position 
# they are displayed at. Position name can be any string. I suggest using top, right ... 
# 
# Ads may be prioritized. Higher priority means higher probability that ad will be selected for display. 
# 
# Clicks on picture and flash can be intercepted and are saved into dc_ad_stat table. 
# It is also possible to limit number of times ad will be displayed or clicked. 
########################################################################
class DcAdRenderer
  
include DcApplicationHelper

########################################################################
#
########################################################################
def initialize( parent, opts={} ) #:nodoc:
  @parent = parent
  @opts   = opts
  @css    = ''
  self
end

########################################################################
# Finds ads that will be rendered. Subroutine of multi method.
########################################################################
def find_ads_multi() #:nodoc:
  ads = DcAd.where( position: @opts[:position], active: true).to_a#, :valid_to.gt => Time.now, :valid_from.lt => Time.now).to_a
#p @opts, ads.size, '*-*-*-*'
  ads.delete_if { |ad| (ad.valid_to and ad.valid_to < Time.now) or 
                       (ad.valid_from and ad.valid_from > Time.now) or 
                       (ad.displays > 0 and ad.displayed >= ad.displays) or
                       (ad.clicks > 0 and ad.clicked >= ad.clicks) }
                   
  ads
end

########################################################################
# This is an experiment of how to render multiple ads on same location simultaneously by
# fade in and out div on which ad resides.
########################################################################
def multi
  return '' if @parent.session[:is_robot] # don't bother if robot
  html = "<div id='ad-#{@opts[:position]}-div'>"
  n = 0
  find_ads_multi.each do |ad|
    div = "ad-#{@opts[:position]}-#{n+=1}"
    html << "<div id='#{div}' style='position: absolute; display: none;'>"
    # all except first are hidden
#    html << n == 1 ? '>' : 'style="display: none;">'
    html << case ad.type
    when 1 then # picture
      picture_link ad
    when 2 then # flash
      flash_link ad
    when 3 then # script
      ad.script
    else
      'Error. Wrong ad type!'
    end
    html << '</div>'
  end
# 
  html << '</div>'
  if n > 0
    js = <<EOJS
  dc_ad_next_slide = function(div, index, max, timeout) {
    index = index + 1;
    div_show = div + index.toString();
    index_h = index - 1;
    if (index_h == 0) index_h = max;
    div_hide = div + index_h.toString();
    $('#' + div_show).fadeIn(1500);
    $('#' + div_hide).fadeOut(1500);

    if (index == max) index = 0; 
    setTimeout( function () { dc_ad_next_slide(div, index, max, timeout); }, timeout);
}

  $(document).ready(function () {
    dc_ad_next_slide("ad-#{@opts[:position]}-", 0, #{n}, 5000)
  });       
EOJS
  html << @parent.javascript_tag(js)
  end
  html
end

########################################################################
# Determines which add will be displayed next. Subroutine of default method.
########################################################################
def find_ad_to_display()
  ads = DcAd.where( dc_site_id: @parent.site._id, position: @opts[:position], active: true).to_a#, :valid_to.gt => Time.now, :valid_from.lt => Time.now).to_a
#p @opts, ads.size, '*-*-*-*'
  ads.delete_if { |ad| (ad.valid_to and ad.valid_to < Time.now) or 
                       (ad.valid_from and ad.valid_from > Time.now) or 
                       (ad.displays > 0 and ad.displayed >= ad.displays) or
                       (ad.clicks > 0 and ad.clicked >= ad.clicks) }
  return nil if ads.size == 0
# Determine ad to display, based on priority. This is of course not totaly accurate, 
# but it will have to do.
  sum = ads.inject(0) {|r, e| r += e.priority}
  rnd = Random.rand(sum)
  r = 0
  ads.each do |e|
    return e if rnd >= r and rnd < r + e.priority
    r += e.priority
  end
  ads.last # we really shouldn't be here
end

########################################################################
# Code for flash ad.
########################################################################
def flash_ad(ad)
  click_tag = ad.link.to_s.size > 5 ? "flashvars=\"clickTag=#{ad.link}\"" : '' 
<<EOT
<div class="link_to_track" id="#{ad.id}">
  <object>
    <param name="wmode" value="transparent" />
    <embed width="#{ad.width}" height="#{ad.height}" src="#{ad.file}" #{click_tag}
           wmode=transparent allowfullscreen='true' allowscriptaccess='always' type="application/x-shockwave-flash"></embed>
  </object>
</div> 

<script type='text/javascript'>
$('##{ad.id}').mousedown(function (e){
    $.post('/dc_common/ad_click', { id: this.id });
    return true;
});
</script>     
EOT
end

########################################################################
# Code for picture ad.
########################################################################
def picture_ad(ad)
  @parent.link_to @parent.image_tag(ad.file), ad.link, id: ad.id, class: 'link_to_track', target: ad.link_target 
end

########################################################################
# Default method for rendering ads. 
########################################################################
def default
  return '' if @parent.session[:is_robot] # don't bother if robot
  html = ''
  if (ad = find_ad_to_display)
# save to statistics, if not in cms
    if @opts[:edit_mode] < 1
      DcAdStat.create!(dc_ad_id: ad.id, ip: @parent.request.ip, type: 1 )
# save display counter  
      ad.displayed += 1
      ad.save
    end
    html << case ad.type
    when 1 then # picture
      picture_ad ad
    when 2 then # flash
      flash_ad ad
    when 3 then # script
      ad.script
    else
      'Error. Wrong ad type!'
    end
  end
  html
end

########################################################################
# Renderer dispatcher. Method returns HTML part of code.
########################################################################
def render_html
  method = @opts[:method] || 'default'
  html = if method and self.respond_to?(method)
    send(method)
  else
    "DcAdRenderer: method #{method} not defined!"
  end
  html  
end

########################################################################
# Render CSS. This method returns css part of code.
########################################################################
def render_css
  @css
end

end
