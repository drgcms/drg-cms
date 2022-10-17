See [GitHub Releases](https://github.com/drgcms/drg-cms/releases) for all future releases

## Changes

## [0.7.0.2] - october 2022
### New features
- mongoid 8 gem and MongoDB 6.0 are tested and used in production
- jquery 3 enabled in cms editor window
- local caching results of dc_user_can_view method gains huge speedups. Especially on huge menus
- categories can now be edited in a tree view. Example of usage of type: method option in result_set

## Bugs resolved:
- redirect_to method requires **allow_other_host: true** option when redirecting to other host. Requirement of Rails 7
- options option for configuring form elements, which are created from javascript objects, are now properly parsed when set as json or yaml parameters  

## [0.6.1.11] - june 2022
### New features
- DRG CMS is tested and running against Ruby 3.1 and Rails 7 in production
- enable wizard like form. Wizard forms extend other forms and select fields to be processed step by step. It paints steps panel on the left side of the form and add next and previous action buttons to top of form. Document processing and saving must be done in control file
- ensure help button is displayed on the form only when there is a help text available
- attribute data-validate html option added. When set to true HTML5 form validations will be ignored on action button clicked. When you have close button on dialog, and you can not close it, because form validations must be met
- when check is used to select documents for processing only document ids are send as parameters. Before that they were send as 'check-id'
- standard fields like created_by, created_at, active, updated_at, updated_by no longer need to be localized for each model
- google analytics GA4 support added
- text_with_select and hidden_field DRG Form fields now trigger change event, when the value is changed
- simplify display of footer record in documents browser. It can now be of Array type. Array columns are in same order as fields defined on form
- model may now define set_history method, which will be called on standard CRUD operations. The idea is to save some extra data in the set history method, which can be later used for revision.
- html_field (ck_editor) value is now saved to parameters on ajax action.

## Bugs resolved:
- in some cases journal of current document was not displayed properly

## [0.6.1.9] - march 2022
### New features
The biggest new feature in this version is trying to match application design to Material design recommendations and replacing the FontAwesome icon fonts with Material design icon set.

Other features:
- form_name and table parameters can be replaced by f and t parameter. This will shorten URL's in menus.
- new action **type: popup** is added to available actions. This action will load the form into a popup window. Other options are the same as for window or link type.
- column (field) in result set can now be painted from Rails helper method and not only from method defined in model

## [0.6.1.5] - december 2021
### New features
- process_ajax_result function has two new options. **parenturl** will change URL on parent dialog and **popup_url** which will popup window and load url address into it
- application locale setting can finally be set by url. Put **&locale=en** into url and all subsequently calls to application will be english localized. To reset to default locale just pass empty **&locale=** parameter
- comment DRG Form field type has now html option which will add html attributes to comment text
- result_set data can now be drawn by custom method with new option **type:**. Option defines type of element which will be used for painting result_set data.<br> 
  **type: default** or omitted. The default (cms_edit/index) painting is used.<br> 
  **type: method**; supports one additional option<br> 
  &nbsp; **eval: my_method_name**; will call (helper) method my_method_name and use its return to paint result_set dialog

## [0.6.1.4] - september 2021
### New features
- requirements updated to Rails 6.1 and Ruby 2.7
- enable Redis caching for fundamental collections. Permissions, site, page and design collections documents. Documents from these collections are usually read on every page load
- document history (journal) shortcut is added to document info icon
- embedded documents are now automatically resized to content height
- help system manager is ready and is located CMS advanced menu. Every DRG Form can have it's help file in help directory. Help dialog can be called from icon in form dialog title
- form name added as id to form dialog, so fields on a form can be selected according to form name
- process_json_request has new focus option, which will transfer focus to defined field on ajax call return
- readonly form can have embedded form which are not readonly. By default readonly embedded forms are also readonly. Readonly form can also have specific actions available. Again by default actions (except back) are not available on readonly forms
- check option is added to result set actions. This enables selection of documents and processing selected documents with ajax index action
- more user friendly mobile experience

## [0.6.0.8] - december 2020
### New features
- form field can also be defined as mongoid model method, not just fields defined in mongoid model (which is basically equal)
- result column value can be obtained by method defined in a mongoid model
- permissions can now be namespaced. In your application you may start all collection names with same first 3 characters and define eg. dc_* permission, which will set permissions for all collections with name starting with dc_.
- dc_temp collection has new order field so result can be ordered
- embedded DRG Form field has now three options for load. default loads embedded form on form load, always loads (refreshes) embedded form each time parent tab is clicked and delay which loads embedded form when parent tab is  selected for the first time
- close action added to form edit options. It will call window.close() javascript code. Can be used when window was opened with window action type
- new DRG Forms field type method defined. Will call any method and display returned HTML code
- form dialog name can now be set dynamically
- dc_format_value won't output 0 if 'z' is present in format parameter.
- line: top and line: bottom parameters will paint horizontal line on a form
- reports made easy with help of prawn gem. Reports are treated like controls and consist of form for selecting data and displaying result, printing report and exporting to spreadsheet
- form fields have got default option which can also be evaluated (eg. Time.now)
- polls can now have javascript code defined. Radio buttons added to polls.
- by default result browser can be sorted by any column (field) defined in result_set options. Default can be disabled by adding sort: n option to field
- result set width option can be set as none or hidden. Used for report which doesn't display field and only exports it to Excel
- run action now checks if user has permissions to run
- result set column sorting can be disabled by defining sort: n option
- poll results may (must) now be confirmed
- Exo variable font is now being used as default font 

## [0.6.0.6] - june 2020
### New features
- index section has got select_field and deny_field option, for granular selection of fields displayed on result set browser
- new DcTemp model is available for browsing temporary data. Unlike DcMemory model, data is saved to database and can persist until clear is requested
- CSS code can now be added to DRG Form on top level or on field level with css option
- javascript code can now be part of DRG Form definition or can be loaded from external js file
- readonly number field is now displayed formatted when  format is specified
- date_picker and datetime_picker have autocomplete code turned to off by default
- ajax action in embedded form field can now update form field on parent form
- embedded DRG Form field can now be used for browsing foreign collection with has_many relation
- embedded DRG Form field can now pass additional parameters to called Form
- recommended control files location is now app/controls folder. app/controllers/drgcms_controls locations will be deprecated
- dc_poll_result model created to save polls result by calling dc_poll.save_results
- all action buttons (on index, result and edit form) can now be of type link,ajax,submit and window. They can all be called with additional parameters and be either enabled or disabled
- index actions can now hold additional input fields (ex. for additional filter fields)
- cmsedit controller has got additional run action, which can be used with ajax actions to directly call any method in controls or any class file.
- checkbox and select fields can now be properly set from ajax call. When return of set select field is array select field choices are set
- choices of select field can now depend on value of another field. <b>depend: other_field_name_on_form</b> option forces select field to dynamically update its choices when depend field changes it's value
- head option added to form. Head is drawn at the top of the form and may display values from fields (methods) from current document, comment or evaluated text data. Definition of head fields is similar to entry fields.
- new delayed option added to embedded DRG Form field. If set to true embedded form is loaded delayed when tab holding embedded field is selected. This minimizes database access when lots of embedded forms is located on tabs
- DRG Form can now be dynamically updated by defining dc_update_form method in control file
- dc_update_method is called after form file has been read and before form processing. Thus whole form can be changed or programmatically created
- display of readonly fields is mostly improved by using readonly HTML5 keyword
- new radio DRG Form field for implementing radio button fields entry fields
- new file_field DRG Form field for classic file upload
- new action DRG Form field can be used to put action anywhere between for entry fields

## [0.6.0.3] - january 2020
### New features
- Rails 6 compatible
- jQuery 3 used as jquery javascript library in production
- SEO optimizations added to dc_page and can be easily added to any document model
- json_ld_structure skeleton can be easily added to any document model
- DRGCMS form can be used to browse any array not only mongodb collections
- form actions can be disabled when editing data. For now only on new document
- gallery can be added to document by adding  boolean field to model and adding dc _render(:dc_gallery) to document renderer
- parent_disabled and parent_opened options added to tree_view DRG CMS form field.
- fa-icons can now be rendered as menu item caption
- renderers moved to app/renderers directory
- all pictures embedded in document body must have alt data set
- DRG CMS form can now include other form
- ajax call result can now be evaluated as javascript code
- autocomplete field can now return field value which is not an id field
- CMS toggle polished. When clicked on left half of toggle current position on display is preserved
- filter condition can now be set, by clicking on column sort icon.

## [0.5.52.14] - may 2019
### New features
- rows an columns on DRG Forms are now created as divs instead of tables
- file_select DRG Forms field has picture preview on the side
- DRG Forms table displaying result set can detect @record_footer variable and if set, draws additional row at the end of result set. This can be used for displaying total row data
- icon position on action button created by dc_link_to method, can now be positioned first or after button caption
- DRG Form embedded field can now be used to browse any collection, not only embedded collections
- menu items can be created dynamically. For example login/logout can be embedded in menu. Menu item can also contain just horizontal line as separator
- DRG Form fields can have HTML5 style validation defined in HTML section. Validations are performed not only on form submit but also on ajax calls
- number_field added to DRG Forms. Number fields can have fixed decimal places, thousands delimiters and are aligned to right
- routes needed by DrgCms are now defined by DrgCms.routes method which can be used in routes.rb
- new forms field <b>tree_select</b>
- new forms field <b>numeric_field</b>
- base DRG_CRM models (dc_site, dc_page, dc_piece, dc_user, dc_olicy_rule) are now defined as concerns.
- dc_site can now inherit policy from other site and thus simplify policy definitions when multiple sites with same users are used on single Rails instance.
- dc_memory model replaces dc_dummy model for editing non DB data
- cms_edit controller is aliased as cms
- menu item may now be calculated when picture values is preceded with @
- horizontal menu can be added to menu by defining < hr > in caption
- iframe options added to dc_page model
- default data for testing created
- formname keyword change to form_name
- table elements replaced by div elements for form. Thus editing data is more flexible on tablets or even mobiles,
- image preview added to file_select field. Can be omitted with preview: no option
- result table can now have @record_footer record which defines values for footer displayed on the bottom of result table
- embedded field can embed other forms not just field embedded in model. Name option must match table option.
- html 5 validations can be added to form fields in html option
- popup message can be displayed as result of ajax call from form
- dc_name4_id can return value of any method defined in model
- removed url collection created for adding removed url-s to sitemap
- dc_check_user_still_valid method added to check if user data saved to session is still valid every defined period of time,
- DRG CMS form fields source code refactored. Code for every field is now defined in its own file

### Bugs resolved
- dc_before_edit callback was not working as expected
- lots of small bugs resolved

## [0.5.52.4] - march 2018
### New features
- Ruby 2.4 is required
- Rails 5.2 compatibility requirements met
- dc_page document has new fields for defining and displaying iframe
- CMS menu has link option which defines direct url link
- DRG Form data entry fields are now built of div elements instead of table elements
- text_with_autocomplete can now return value which is not dependent on relation in another collection
- data entry form is automatically resized to full size when tab is selected.

### Bugs resolved
- tree_select field returns BSON objects when BSON object is selected and array when multiple options are selected. It was returning strings before.
- refactoring formname DRG Forms option to form_name

## [0.5.51] - september 2017
### New features
- Rails version 5.1 compatibility
- Ruby version 2.3 is now required
- select field with multiple can now properly process non BSON array values
- DRG CMS Form readonly field with readonly : yes option will not be saved to database on save
- dc_dummy collection will be deprecated and replaced with dc_memory collection. Name was chosen unfortunately  
- DrgForms can now be used for editing YAML settings saved in dc_page document. This enables editing dynamic settings of elements embedded in design

## [0.5.50] - may 2017
### New features
- Rails 5.0 compatibility
- category types can now be defined in dc_big_table under dc_category_type key
- DrgCms gem routes can now be defined as DrgCms.routes
- new field tree_select added to DRG CMS Forms. Tree select will be used as data entry field for categories instead of select field with multiple option
- switch to Rails concern for main model definitions which may be reused
- site policy can be inherited from other site
- menus can now belong to site
- clear_link method is now a class method of DcPage model and can thus be called directly from other parts of application

### Bugs resolved
- documents can now be undeleted from journal

## [0.5.10] - february 2017
### New features
- browsing array of hashes is now possible with DRG Forms
- simple browsing of all defined models and field definitions added to CMS System menu
- new result_set options table_style, table_class, tr_style, tr_class, td_style, td_class. Welcome colors to result_set browser
- result_set has been renewed for more modern design. Header elements have now sorting icons
- dblclick and click actions can now be defined on result set and can fire any action when clicked or double clicked on result set row
- main CMS menu was becoming to large and was divided into two menus
- result set browse filter data entry redesigned. Values can now be entered directly on actions area. Value of entered fied is also retained beetwen calls
- new DcInternals model introduced. It will be used for accessing internal variables
- DRG Forms has new option columns. Option defines number of columns per tab or fields. Field option also got colspan option indicating over how many columns field spans
- DRG Forms field size can now also be defined on same level as field type. Before it was defined in html sublevel
- jQuery javascript library forced to jQuery2
- choices for select fields are now UTF-8 sorted since MongoDB does not provide utf sorting
- placeholder text added for text_autocomplete field. It can also be defined in form field html options
- filters option can now have "like" keyword for fields that are not defined on form. For example created_by like user_id
- table_style added to result_set DRGCMS Forms option. This allows CSS style like width: 150% which will result in horizontal scroler on table and view more columns on result set.
- result_set filter now has is empty option allowing to filter fields with null value.
- filter OFF icon now displays currently active filter when hovered.
- request_process field added to dc_site collection. It allowis for site to have different requests processing as defined in rails routes file. Single rails instance can now mix single document sites with complex sites.
- multiple option is added to DRGCMS Forms select_field.
- is_email? class method added to dc_user model.
- form generator has now list of all model fields added at the end of generated form. Field names can be used as template in YAML translation file.
- dc_choices4_field method implemented. It returns choices that are defined in localization files.
- categories field changed from multitext_autocomplete to select field with multiple options.
- a poll form can now be surrounded by div tag thus allowing for additional styling of polls
- drgcms_controlls files can now also be defined only as control files.
- journal documents can now be filtered by document id
- CMS menu redesigned. Instead of pulldown menus are now displayed fixed on the left side of edit area

### Bugs resolved
- associated menu can now be selected on dc_page form also for non dc_simple_menu menus
- improved readonly display of select and text_autocomplete DRG Forms fields.
- text_autocomplete field is set to nil when content of field is deleted.
- jQuery migrate udated to version 1.3. This was required by jquery-rails gem which included latest version of jQuery which resulted in an runtime error.
- call before_new callback only when new empty record has been created.
- prevent double form submit when browser is restarted.
- when user has no role defined guest role is automatically applied
- dc_cleanup rake task deletes 1000 session documents created by robots at once instead of all which ended in error if number of documents was higher then 100.000


## [0.5.7] - november 2015
### New features
- single site document. All data for the site can be saved to single dc_site document and processed by dc_single_sitedoc_request
- site parts can now also be saved and collected from dc_site document
- CMS menu done right
- Page title is now set from dc_page_renderer default method

### Bugs resolved
- Corrected bug when multitext_autocomplete field was not displaying right values when displayed readonly
- dc_choices4 now checks if model has active field defined and returns only choices of documents that have active field value set to true
- design and page edit icons are now displayed only when design or page documents are available
- return_to from drgcms_control was not properly handled
- mouse cursor now changes to pointer when moved over ajax link
