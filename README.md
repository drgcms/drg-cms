# DrgCms

DRG CMS is advanced way of programming application for Ruby on Rails. 
Instead of creating controllers and views for each collection (table), 
DRG CMS introduces single Cmsedit controller. All CRUD database actions are 
controlled by DRG Forms file, which can have hundreds of data entry fields 
and still be easy to maintain and update.
 
DRG CMS uses MongoDB, leading NO-SQL document database, as database back-end 
with a help of mongoid gem. Mongoid's flexible document model defines all 
document fields, indexes, dependencies, validations in single model source file with 
no Rails migrations required. When collection model is defined, data entry DRG Form 
can easily be generated with form generator.

DRG CMS can be used for rapid development of complex, data-entry intensive web 
sites as well as building your private, in-house, Intranet applications. At
the same time it can be used as CMS system with support for running 
multiple web sites on single Ruby on Rails instance.

DRG CMS has built-in user friendly role based database access system. Administrator
defines roles and roles rights (no access, can read, can edit) as web site policies.
Roles are then assigned to users and policies can be assigned to documents (web pages) 
or even parts of a document.

Project Tracking
----------------

* [DrgCms Website and Documentation](http://www.drgcms.org)

Compatibility
-------------

DRG CMS is being actively developed since 2012 and has been live tested in production 
since beginning. It runs against latest technology Ruby (3.0), Rails (6.1) 
and MongoDB (4.4) and had so far little or no problems advancing to latest versions 
of required programs.

Documentation
-------------

Please see the DRG CMS website for up-to-date documentation:
[www.drgcms.org](http://www.drgcms.org)

License (MIT LICENCE)
---------------------

Copyright (c) 2012-2021 Damjan Rems

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
