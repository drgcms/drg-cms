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
# Implementation of custom DRG CMS form field. Method field will call method or class method
# defined in eval option and add returned code to HTML output code. This might prove usefull in 
# cases where form contains complex dta stgructer or set of pictures which can not
# be simply displayed by any other field.
#   
# Form example:
#    50:
#      name: galery
#      type: method
#      eval: show_gallery
#      or
#      eval: MyClass.show_gallery
#      
###########################################################################
class Method < DrgcmsField

###########################################################################
# Render file_select field html code
###########################################################################
def render
  # might be defined as my_method or MyClass.my_method
  clas, method = @yaml['eval'].split('.')
  if method.nil?
    if @parent.respond_to?(clas)
      @html << @parent.send(clas, @record, @yaml, @readonly) 
      return self
    end
  else
    klass = clas.camelize.constantize
    if klass.respond_to?(method)
      @html << klass.send(method, @record, @yaml, @readonly) 
      return self
    end
  end   
  @html << "Error: #{@yaml['name']} : #{@yaml['eval']} not defined!"
  self
end

end
end
