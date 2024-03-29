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
  flash[:record] ||= {}

  created_by = flash[:record][:created_by]
  qry = created_by.present? ? DcImage.where(created_by: created_by) : DcImage.all

  short_name = flash[:record][:short]
  qry = qry.and(short: /#{short_name}/i) if short_name.present?

  category = flash[:record][:categories]
  qry = qry.and(categories: category) if category.present?
  qry.limit(30).order_by(created_at: -1)
end

######################################################################
# Invoke images search. Just forward parameters and reload form. Filter parameters will
# be taken into account on reload.
######################################################################
def images_search
  flash[:record] = {}
  flash[:record][:short] = params[:record][:short]
  flash[:record][:created_by] = params[:record][:created_by]
  flash[:record][:categories] = params[:record][:categories]

  url = url_for(controller: :cmsedit, table: :dc_image, form_name: :dc_image_search, field_name: params[:field_name])
  render json: { url: url }
end

######################################################################
# Set some default values when new record
######################################################################
def dc_new_record
  default_sizes = dc_get_site.params.dig('dc_image', 'sizes').to_s.split(',')
  @record.size_ls = default_sizes.shift
  @record.size_ms = default_sizes.shift
  @record.size_ss = default_sizes.shift
end

######################################################################
# Save uploaded file if selected and extract properties data
######################################################################
def dc_before_save
  return if @record.size_o.present? || !params[:upload_file]

  input_file_name = params[:upload_file].original_filename
  type = File.extname(input_file_name).to_s.downcase.gsub('.', '').strip
  unless %w(jpg jpeg png gif svg webp).include?(type)
    flash[:error] = t 'drgcms.dc_image.wrong_type'
    return false
  end
  name = File.basename(input_file_name)
  path = File.dirname(params[:upload_file].tempfile)

  @record.img_type = dc_get_site.params.dig('dc_image', 'img_type') || type
  @record.short = File.basename(input_file_name, '.*') if @record.short.blank?
  @record.name  = File.join(path, name)
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

  original_file_name = Rails.root.join('public', images_location, "#{@record.id}-o.#{@record.img_type}")
  @record.name = original_file_name unless @record.name.present? && File.exist?(@record.name)
  if !File.exist?(@record.name)
    flash[:warning] = t 'drgcms.dc_image.no_file'
    return
  end

  image_magick_do(new_size, new_file_name)
end

######################################################################
# Crop and resize image
#
# @new_size [String] new_size widthxheight+offsetx+offsety 300x200+1000+0
# @file_name [String] Image file name
######################################################################
def image_magick_do(new_size, file_name)
  image = MiniMagick::Image.open(@record.name)

  a = new_size.split(/x|\+/).map(&:to_i)
  a += [0, 0] if a.size < 4
  image_offset(image, a[2, 2]) if a[2, 2] != [0, 0]

  img_w, img_h = image.width, image.height
  new_w, new_h = a[0, 2]
  img_ratio = img_w.to_f / img_h
  new_ratio = new_w.to_f / new_h
  formula = if new_ratio > img_ratio
              "#{img_w}x#{img_w/new_ratio}+0+0"
            else
              "#{img_h*new_ratio}x#{img_h}+0+0"
            end
  image.crop(formula)

  image.resize("#{new_w}x#{new_h}")
  image.write(file_name)
  image_reduce(file_name)
end

######################################################################
# Reduce image quality of image
######################################################################
def image_reduce(file_name)
  if (quality = dc_get_site.params.dig('dc_image', 'quality').to_i) > 0
    convert = MiniMagick::Tool::Convert.new
    convert << file_name
    convert.quality(quality)
    convert << file_name
    convert.call
  end
end

######################################################################
# Offset image if requested
######################################################################
def image_offset(image, offset)
  img_w, img_h = image.width - offset[0], image.height - offset[1]
  image.crop("#{img_w}x#{img_h}+#{offset[0]}+#{offset[1]}")
end

######################################################################
# Returns location of images files relative to public directory
######################################################################
def images_location
  dc_get_site.params.dig('dc_image', 'location') || 'images'
end

end
