# drg-cms

[![Gem Version](http://img.shields.io/gem/v/drg_cms.svg)](https://rubygems.org/gems/drg_cms)
[![Gem Downloads](https://img.shields.io/gem/dt/drg_cms.svg)](https://rubygems.org/gems/drg_cms)


DRG CMS simplifies the programming of business applications. 
Minimal database experience and only basic programming skills are needed 
to create a data entry program. You can do it in 6 simple steps.

Step 1: Create Model<br>
Step 2: Generate Form<br>
Step 3: Edit Form<br>
Step 4: Define Labels and Help Text<br>
Step 5: Create Controls File (if required)<br>
Step 6: Include in application menu<br>

Most of the time, you will end up with two source files.

<b>Model:</b> Model file is a database document definition file written in Ruby
language. Model file holds fields definitions, 
index definitions, dependencies, validations, callbacks and transformations 
for a database document (record). 

An example of a typical model file app/models/note.rb

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

<b>Form:</b> Form file is a text file, written in the YAML markup language. It consists
of three main parts.<br>

<b>index:</b> Which defines actions usually performed on database documents or 
set of document.<br>
<b>result_set:</b> Defines set of documents, document fields and actions 
which can be performed on a document.<br>
<b>form:</b> Defines data entry fields for editing and viewing the document.<br>

Example of form file for Note model app/forms/note.yaml

```yaml
table: note

index:
  filter: search as text_field
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

Add labels and help text to your project locales files.
```yaml
en:
  helpers:
    label:
      diary:
        tabletitle: Diary
        choices4_duration: "10 min:10,15 min:15,20 min:20,30 min:30,45 min:45,1 hour:60,1 hour 30 min:90,2 hours:120,2 hours 30 min:150,3 hours:180,4 hours:240,5 hours:300,6 hours:360,7 hours:420,8 hours:480"

        title: Title
        body: Description
        time_started: Start time
        duration: Duration 
        search: Search
        user_id: Owner

    help:
      diary:
        title: Short title
        body: Description of event or note
        time_started: Time or date when note is created or event started
        duration: Duration of event
        search: Data used for searching data
        user_id: Owner of the note
  ```
Combination of two source files and localisation data makes application
data entry program. Application data entry program implements all data
entry operations on a database:<br>
<li>add new document<br>
<li>edit document<br>
<li>delete document<br>
<li>view document
<br><br>Add it into your application menu with this code:

```ruby
dc_link_to('Notes', 'book', { table: 'note' }, target: 'iframe_edit')
```

And when you need advanced program logic, you will implement it in 
the control file. Control files code is injected into cmsedit
controller during form load, and provides additional program logic required
by data entry program.
```ruby
######################################################################
# Drgcms controls for Notes application
######################################################################
module NoteControl

######################################################################
# Fill in currently logged user on new record action.
######################################################################
def dc_new_record
  @record.user_id = session[:user_id]
  @record.time_started = Time.now.localtime
end

###########################################################################
# Allow only current user documents to be displayed
###########################################################################
def current_user_documents
  user_filter_options(Note).and(user_id: session[:user_id]).order_by(id: -1)
end

end
```

## Features
DRG CMS uses Ruby on Rails, one of the most popular frameworks for 
building web sites. Ruby on Rails guarantees highest level of application security and huge base of extensions which will help you when your application grows.
<br><br>
DRG CMS uses MongoDB, leading NO-SQL document database, as database 
back-end with a help of mongoid gem. Mongoid's flexible document model 
defines all document fields, indexes, dependencies, validations in a 
single model file with no database migrations required.
<br><br>
DRG CMS has built-in user friendly role based database access system. Administrator
defines roles and roles rights (no access, can read, can edit) as web site policies.
Roles are then assigned to users and policies can be assigned to documents (web pages)
or even parts of a documents.
<br><br>
DRG CMS can coexist with other frameworks which use MongoDB as database
back-end. Use your favorite framework for data presentation and 
use DRG Forms for rapid development of data entry forms.
<br><br>
DRG CMS can coexist with other databases and Rails controllers. I can 
highly recommend using DRG CMS in heterogeneous database Intranet 
projects. For the last few years, DRG has been used for development of 
an in-house Intranet portal which uses MongoDB as primary database and
connects frequently to Oracle and MS-SQL databases.

## Installation

Go and [jumpstart](https://github.com/drgcms/drg-portal-jumpstart)
internal portal application with DRG CMS in just few minutes.

Project Tracking
----------------

* [Visit DRG CMS web site](http://www.drgcms.org)

Compatibility
-------------

DRG CMS is being actively developed since 2012 and has been live tested in production 
since beginning. It runs against latest technology Ruby (3.1), Rails (7.0) 
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
