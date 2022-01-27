# What is DRG CMS

DRG CMS simplifies the programming of business applications. 
No database experience and only basic programming skills are needed to create a data entry program. You can do it in 6 simple steps.

Step 1: Create Mode<br>
Step 2: Generate Form<br>
Step 3: Edit Form<br>
Step 4: Define Labels and Help Text<br>
Step 5: Create Controls File (if required)<br>
Step 6: Include in Menu<br>

Most of the time, you will end up with two source files.

Model file is a Ruby source file, which holds fields definitions, 
index definitions, dependencies, validations, transformations 
for a document (record). This is an example of a typical simple 
model file example.

```ruby
class Note
include Mongoid::Document
include Mongoid::Timestamps

field   :title,       type: String
field   :body,        type: String
field   :time_begin,  type: DateTime
field   :duration,    type: Integer
field   :search,      type: String

field   :user_id,     type: BSON::ObjectId

index   user_id: 1

validates :title,      presence: true
validates :time_begin, presence: true
validates :duration,   presence: true

end
```

Form file is a text file, written in the YAML markup language, and 
defines fields and actions which make application web facing view.

```yaml
table: note

index:
  filter: title
  actions: standard

result_set:
  filter: current_users_documents
  actions:
    1: edit

  columns:
    10:
     name: title
     width: 25%
    20:
      name: time_started
      width: 10%
      format: '%d.%m.%Y'
    30:
      name: duration

form:
  fields:
  10:
    name: user_id
    type: readonly
    eval: dc_name4_id,dc_user,name
    default:
      eval: 'session[:user_id]'    
  20:
    name: title
    type: text_field
    size: 50
  30:
    name: time_started
    type: datetime_picker
    options:
      step: 15
  40:
    name: duration
    type: select
  50:
    name: body
    type: html_field
    options: "height: 500"
```

Include it into your application menu with this line:

```ruby
dc_link_to('Notes', 'book', { table: 'note' }, target: 'iframe_edit')
```

And when you need advanced program logic, you will implement it in 
the controls source file.

DRG CMS uses Ruby on Rails, one of the most popular frameworks for 
building web sites. Ruby on Rails guarantees highest level of application security and huge base of extensions which will help you when your application grows.

DRG CMS uses MongoDB, leading NO-SQL document database, as database 
back-end with a help of mongoid gem. Mongoid's flexible document model 
defines all document fields, indexes, dependencies, validations in a 
single model file with no database migrations required.

DRG CMS has built-in user friendly role based database access system. Administrator
defines roles and roles rights (no access, can read, can edit) as web site policies.
Roles are then assigned to users and policies can be assigned to documents (web pages)
or even parts of a documents.

DRG CMS can coexist with other frameworks which use MongoDB as database
back-end. Use your favorite framework for data presentation and 
use DRG Forms for rapid development of data entry forms.

DRG CMS can coexist with other databases and Rails controllers. I can 
highly recommend using DRG CMS in heterogeneous database Intranet 
projects. For the last few years, DRG has been used for development of 
an in-house Intranet portal which uses MongoDB as primary database and
connects frequently to Oracle and MS-SQL databases.

Go and [jumpstart](https://github.com/drgcms/drg-portal-jumpstart) 
internal portal application with DRG CMS in just few minutes.

Project Tracking
----------------

* [Visit DRG CMS web site](http://www.drgcms.org)

Compatibility
-------------

DRG CMS is being actively developed since 2012 and has been live tested in production 
since beginning. It runs against latest technology Ruby (3.0), Rails (6.1) 
and MongoDB (5.0) and had so far little or no problems advancing to latest versions 
of required programs.

Documentation
-------------

Please see the DRG CMS website for up-to-date documentation:
[www.drgcms.org](http://www.drgcms.org)

License (MIT LICENCE)
---------------------

Copyright (c) 2012-2022 Damjan Rems

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
