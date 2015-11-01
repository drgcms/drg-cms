# DrgCms

DRG CMS is alternative way of programming application for Ruby on Rails. Instead of creating controllers and views for each collection (table) model, DRG CMS introduces single Cmsedit controller which uses DRG Forms to control CRUD database operations. 
 
DRG CMS uses Mongo DB, leading NO-SQL document database, as database back-end with a help of mongoid gem. Mongoid's flexible document model defines all document fields, indexes, dependencies, validations in single model file with no Rails migrations required.

It has built-in user friendly role based access system and it can be easly extended with help of Ruby on Rails plugin system.

DRG CMS can be used for rapid development of complex, data-entry intensive web sites as well as building your private, in-house, Intranet applications.

Project Tracking
----------------

* [DrgCms Website and Documentation](http://www.drgcms.org)

Compatibility
-------------

DRG CMS is tested against Ruby 2.0, 2.1 and 2.2, Rails 4.2, Mongoid 4 and 5, MongoDB 2.4 and 2.6

Documentation
-------------

Please see the DRG CMS website for up-to-date documentation:
[www.drgcms.org](http://www.drgcms.org)

License
-------

Copyright (c) 2012-2015 Damjan Rems

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Credits
-------

Damjan Rems: damjan dot rems at gmail dot com
