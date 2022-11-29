#--
# Copyright (c) 2022+ Damjan Rems
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
# DrgcmsControls for DcImage data entry.
######################################################################
module DcImageControl

######################################################################
#
######################################################################
def search_filter
  params[:p_record_created_by] = session[:user_id] if params[:p_record_created_by].nil?

  qry = DcImage.where(created_by: params[:p_record_created_by])
  qry = qry.and(short: /#{params[:p_record_short]}/i) if params.dig(:p_record_short).to_s.size > 2
  qry = qry.and(categories: :p_record_categories) if params.dig(:p_record_categories).to_s.size > 2
  qry.limit(20).order_by(created_at: -1)
end

######################################################################
# Invoke images search. Just forward parameters and reload form. Filter parameters will
# be taken into account on reload.
######################################################################
def images_search
  url = url_for(controller: :cmsedit, table: :dc_image, form_name: :dc_image_search, p_record_short: params[:record][:short],
                p_record_created_by: params[:record][:created_by], p_record_categories: params[:record][:categories] )
  render json: { url: url }
end

######################################################################
# Save uploaded file if selected and extract properties data
######################################################################
def dc_before_save
  return unless params[:upload_file]

  type = File.extname(params[:upload_file].original_filename).to_s.downcase.gsub('.', '').strip
  unless %w(jpg jpeg png gif svg webp).include?(type)
    flash[:error] = t 'drgcms.dc_image.wrong_type'
    return false
  end
  name = File.basename(params[:upload_file].original_filename)
  path = File.dirname(params[:upload_file].tempfile)
  @record.img_type = type
  @record.name  = File.join(path, name)
  @record.short = File.basename(params[:upload_file].original_filename, '.*') if @record.short.blank?
  FileUtils.mv(params[:upload_file].tempfile, @record.name, force: nil)
end

######################################################################
# Prepare additional images
######################################################################
def dc_after_save
  %w[l m s o].each { |size| image_convert(size) }
end

private

######################################################################
#
######################################################################
def image_convert(which)
  new_file_name = "#{@record.id}-#{which}.#{@record.img_type}"
  new_file_name = Rails.root.join('public', images_location, new_file_name)
  new_size = @record["size_#{which}"]
  # remove file if not needed
  if new_size.blank?
    FileUtils.rm(new_file_name) if File.exist?(new_file_name)
    return
  end

  unless File.exist?(@record.name)
    flash[:warning] = t 'drgcms.dc_image.no_file'
    return
  end

  image_magick_do(new_size, new_file_name)
end

######################################################################
# Crop and resize image
#
# @param [String] new_size wxh 300x200
# @param [String] New image file name
######################################################################
def image_magick_do(new_size, file_name)
  image = MiniMagick::Image.open(@record.name)
  img_w, img_h = image.width, image.height

  a = new_size.split(/x|\+/).map(&:to_i)
  a += [0, 0] if a.size < 4
  new_size = a[0, 2].join('x')
  offset = a[2, 2].join('+')

  new_w, new_h = new_size.split('x').map(&:to_i)
  img_ratio = img_w.to_f / img_h
  new_ratio = new_w.to_f / new_h
  if new_ratio > img_ratio
    if a[2] > 0
      #f = "#{img_w - a[2]}x#{img_h}+0+0"
    else
      #f = "#{img_w}x#{img_w/new_ratio}+#{offset}"
    end
    f = "#{img_w}x#{img_w/new_ratio}+#{offset}"
    image.crop(f)
  elsif new_ratio < img_ratio
    if a[3] > 0
      #f = "#{img_w}x#{img_h - a[3]}+0+0"
    else
      #f = "#{img_h*new_ratio}x#{img_h}+#{offset}"
    end
    f = "#{img_h*new_ratio}x#{img_h}+#{offset}"
    image.crop(f)
  end

  image.resize(new_size)
  image.write(file_name)
  image_magick_reduce(file_name)
end

######################################################################
# Reduce image quality of image
######################################################################
def image_magick_reduce(file_name)
  if (quality = dc_get_site.params.dig('dc_image', 'quality').to_i) > 0
    convert = MiniMagick::Tool::Convert.new
    convert << file_name
    convert.quality(quality)
    convert << file_name
    convert.call
  end
end

######################################################################
# Returns location of images files relative to public directory
######################################################################
def images_location
  dc_get_site.params.dig('dc_image', 'location') || 'images'
end

end
