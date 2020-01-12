/*
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
*/

  mouseDown = false;

/*******************************************************************
 * Find and extract parameters value from url
 *******************************************************************/
$.getUrlParam = function(name) {
  var results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(window.location.href);
  if (results == null) return null;
  return results[1] || 0;
};

/*******************************************************************
 * Dump all attributes to console
 *******************************************************************/
dumpAttributes = function(obj) {
  console.log('Dumping attributes:');
  $.each(obj.attributes, function() {
    console.log(this.name,this.value);
  });
};

/*******************************************************************
 * Trying to remove background from iframe element. It is not yet working.
 *******************************************************************/
remove_background_from_iframe = function(obj) {
  var head = obj.head;
  var css = '<style type="text/css">' +
            'body{background: none; background-picture:none; } ' +
            '</style>';
  $(head).append(css);    
};

/*******************************************************************
 * Will update select field on the form which select options are dependend on other field
 *******************************************************************/
update_select_depend = function(select_name, depend_name, method) {
  var select_field = $('#'+select_name);
  var depend_field = $('#'+depend_name);
 /* 
  $.ajax({
    url: "/dc_common/autocomplete",
    type: "POST",
    dataType: "json",
    data: { input: request.term, table: "#{table}", search: "#{search}" #{(',id: "'+@yaml['id'] + '"') if @yaml['id']} },
    success: function(data) {
      response( $.map( data, function(key) {
        return key;
      }));
    }
  });  
*/  
  
};

/*******************************************************************
 * Format number input field according to data
 *******************************************************************/
format_number_field = function(e) {
  var decimals  = e.attr("data-decimal") || 2;
  var delimiter = e.attr("data-delimiter") || '.';
  var separator = e.attr("data-separator") || ',';
  var currency  = e.attr("data-currency") || '';
  var whole = e.val().split(separator)[0];
  var dec   = e.val().split(separator)[1];
// save value to hidden field which will be used for return 
  var field = '#' + e.attr("id").slice(0,-1);
  var value = e.val().replace(delimiter,'.');

  $(field).val( parseFloat(value).toFixed(decimals) );

// decimal part
  if (dec == null) dec = '';
  dec = dec.substring(0, decimals, dec);
  while (dec.length < decimals) dec = dec + '0';
// whole part 
  if (whole == null || whole == '') whole = '0';
  var ar = [];

  while (whole.length > 0) { 
    var pos1 = whole.length - 3
    if (pos1 < 0) pos1 = 0;
    ar.unshift(whole.substr(pos1,3)); 
    whole = whole.slice(0, -3); 
  };

  if (delimiter !== '') whole = ar.join(delimiter);
  e.val(whole + separator + dec + currency);
};
  
/*******************************************************************
 * Activate jquery UI tooltip. This needs jquery.ui >= 1.9
 *******************************************************************/
/*
$(function() {
  $( document ).tooltip();
});
*/

/*******************************************************************
 * Process json result from ajax call and update parts of document.
 * I invented my own protocol which is arguably good or wrong.
 * 
 * Protocol consists of operation and value which are returned as json by
 * called controller. Controller will return an ajax call usually like this:
 *    render json: {operation: value}
 *    
 * Operation is further divided into source and determinator which are divided by underline char.
 *    render json: {#div_status: 'OK!'}
 * will replace html in div="status" with value 'OK!'. Source is '#div' determinator is 'status'.
 * 
 * Possible operators are:
 *  record_name: will replace value of record[name] field on a form with supplied value
 *
 *  msg_error: will display error message.
 *  msg_warn: will display warning message.
 *  msg_info: will display informational message.
 *  
 *  popup: will display popup message
 *  
 *  #div_divname : will replace divname with value
 *  #div+_divname : will append value to divname
 *  #+div_divname : will prepend value to divname 
 *  .div_classname : will replace all accurencess of classname with value
 *  .+div_classname : will prepend value to all accurencess of classname
 *  .div+_classname : will append value to all accurencess of classname
 *  
 *  url_: Will force loading of url supplied in value into same window
 *  window_: Will force loading of url supplied in value into new window
 *  reload_: Will reload current window
 *  
 *  Operations can be chained and are executed sequentialy.
 *    render json: {'window_' => "/dokument.pdf", 'reload_' => 1}.to_json
 *  will open /dokument.pdf in new window and reload current window.
 *  
 *    render json: {'record_name' => "Damjan", 'record_surname' => 'Rems'}.to_json
 *  will replace values of two fields on the form.
 *******************************************************************/

process_json_result = function(json) {
  var i,operation,what, selector;
  $.each(json, function(key, val) {
    i = key.search('_');
    if (i > 1) {
      operation = key.substring(0,i);
      what = key.substring(i+1,100);
    } else {
      operation = key;
      what = '';
    }
//  
    switch (operation) {
    // update field 
    case 'record':
      $('#'+key).val(val);
      break;
    // display message   
    case 'msg': 
      selector = 'dc-form-' + what;
      if ( $('.'+selector).length == 0 ) {
        val = '<div class="' + selector + '">' + val + '</div>';
        $('.dc-title').after(val);
      } else {
        $('.'+selector).html(val);
      }
      break;
    // display popup message
    case 'popup':
      $('#popup').html(val);
      $('#popup').bPopup({ speed: 650, transition: 'slideDown' });            

    // update div 
    case '#div+':
      $('#'+what).append(val);
      break;
    case '#+div':
      $('#'+what).prepend(val);
      break;
    case '#div':
      $('#'+what).html(val);
      break;
    case '.div+':
      $('.'+what).append(val);
      break;
    case '.+div':
      $('.'+what).prepend(val);
      break;
    case '.div':
      $('.'+what).html(val);
      break;
    // goto url 
    case 'url':
      window.location.href = val;
      break;
    case 'alert':
      alert(val);
      break;
    case 'window':
      w = window.open(val, what);
      w.focus();        
      break;
    case 'eval':
      eval (val);
      break;
    case 'reload':
      location.reload(); 
      break;
    default: 
      console.log("DRGCMS: Invalid ajax result operation: " + operation);
    }
  });
};

/*******************************************************************
 * Will reload window
 *******************************************************************/
function dc_reload_window() {
  location.reload(); 
}

/*******************************************************************
 * Will select first editable input field on form. Works only when tab
 * is selected. Still have to find out, what to do on initial display.
 *******************************************************************/
function select_first_input_field(div_name) {
  $(div_name + " :input:first").each( function() {
    this.focus();
    return true;
  });
}

/*******************************************************************
 * Will scroll to position on the screen. This is replacement for 
 * location.hash, which doesn't work in Chrome.
 * 
 * Thanks goes to: http://web-design-weekly.com/snippets/scroll-to-position-with-jquery/
 *******************************************************************/
$.fn.dc_scroll_view = function () { 
  return this.each(function () {
    $('html, body').animate({
      scrollTop: $(this).offset().top - 100
    }, 500);
  });
};

/*******************************************************************
 * 
 *******************************************************************/
$(document).ready( function() {
/* This could be the way to focus on first input field on document open
  if ( $('.dc-form')[0] ) {
// resize parent iframe to fit selected tab size
    var div_height = $('.dc-form')[0].clientHeight + 130;
    window.frameElement.style.height = div_height.toString() + 'px';
//    select_first_input_field('.dc-form');
  }
*/
 /*******************************************************************
  * It will scroll display to ypos if return_to_ypos parameter is present
  *******************************************************************/
  if (window.location.href.match(/return_to_ypos=/))
  {
    window.scrollTo(0, $.getUrlParam('return_to_ypos'));
  }
  
 /*******************************************************************
  * Register ad clicks
  *******************************************************************/
  $('a.link_to_track').click(function() {
    $.post('/dc_common/ad_click', { id: this.id });
    return true;
  });
  
 /*****************************************************************
 * Toggle CMS mode. When clicked on left 30 pixels, window will be scrolled approximately 
 * to the position wher toggle was clicked. When clicked from pixel 31 and on it will
 * stay on the top of window.
 ******************************************************************/  
  $('.cms-toggle').bind('click', function(e) {
    var url = '/dc_common/toggle_edit_mode?return_to=' + window.location.href;
    if (e.pageX < 30) url = url + '&return_to_ypos=' + e.pageY ;
    window.location.href = url;
  });
 
 /*******************************************************************
  * Popup or close CMS edit menu on icon click
  *******************************************************************/
  $('.drgcms_popmenu').on('click',function(e) { 
    $(e.target).parents('dl:first').find('ul').toggleClass('div-hidden'); 
  });

  /*******************************************************************
  * Popup CMS edit menu option clicked
  *******************************************************************/
  $('.drgcms_popmenu_item').on('click',function(e) {
    url = e.target.getAttribute("data-url");
    $('#iframe_cms').attr('src', url);
//    $('#iframe_cms').width(1000).height(1000);
// scroll to top of page and hide menu    
    window.scrollTo(0,0);
    $(e.target).parents('dl:first').find('ul').toggleClass('div-hidden');
  });

 /*******************************************************************
  * Sort action clicked on cmsedit
  *******************************************************************/
  $('.drgcms_sort').change( function(e) {
    table = e.target.getAttribute("data-table");
    sort = e.target.value; 
    e.target.value = null;
    window.location.href = "/cmsedit?sort=" + sort + "&table=" + table;
  });
  
 /*******************************************************************
  * Tab clicked on form. Hide old and show selected div.
  *******************************************************************/
  $('.dc-form-li').on('click', function(e) { 
// find li with dc-form-li-selected class. This is our old tab
    var old_tab_id = null;
    $(e.target).parents('ul').find('li').each( function() {
      if ($(this).hasClass('dc-form-li-selected')) {
// when not already selected toggle dc-form-li-selected class and save old tab
        if ($(this) !== $(e.target)) {
          $(this).toggleClass('dc-form-li-selected');
          $(e.target).toggleClass('dc-form-li-selected');
          old_tab_id = this.getAttribute("data-div");
        }
        return false;
      }
        
    }); // show selected data div 
    if (old_tab_id !== null) {
      $('#data_' + old_tab_id).toggleClass('div-hidden');
      $('#data_' + e.target.getAttribute("data-div")).toggleClass('div-hidden');
// resize parent iframe to fit selected tab size
      var div_height = document.getElementById('data_' + e.target.getAttribute("data-div")).clientHeight + 130;
        window.frameElement.style.height = div_height.toString() + 'px';
// it would be too easy      $('#cmsform :input:enabled:visible:first').focus();
      select_first_input_field('#data_' + e.target.getAttribute("data-div"));
    }
  });  

/*******************************************************************
 * Resize iframe_cms to the size of its contents. Make at least 500 px high
 * unless on initial display.
 *******************************************************************/
  $('#iframe_cms').on('load', function() {
//    alert('bla 1');
    new_height = this.contentWindow.document.body.offsetHeight + 50;
    if (new_height < 500 && new_height > 60) new_height = 500;
    this.style.height = new_height + 'px'; 
// scroll to top
    $('#iframe_cms').dc_scroll_view();
  });

/*******************************************************************
 * Same goes for editiframe. Resize it + 30px
 * unless on initial display with no data 
 *******************************************************************/
  $('#iframe_edit').on('load', function() {
//    console.log(this.contentWindow.document.body.offsetHeight);
    if (this.contentWindow.document.body.offsetHeight > 10) {
      this.style.height = (this.contentWindow.document.body.offsetHeight + 30) + 'px'; 
// scroll to top
      $('#iframe_edit').dc_scroll_view();
    }
  });
  
/*******************************************************************
 * Process Ajax call on cmsedit form actions
 *******************************************************************/
  $('.dc-link-ajax').on('click', function(e) {
// check HTML5 validations
    if ($("form")[0] && !$("form")[0].checkValidity() ) {
      $("form")[0].reportValidity();
      return false;
    }
    var target = e.target;
    var req    = target.getAttribute("data-request");
// Get values from elements on the page:
    if (req == "script") {
      eval (target.getAttribute("data-script"));
      return false;
    }
    else if (req == "post") { 
      data = $('form').serialize(); 
//      alert(data);
    }
    else { 
      data = {}; 
      req = 'get'; // by default
    }
    
    $('.dc-spinner').toggleClass('div-hidden');   
    $.ajax({
      url: target.getAttribute("data-url"),
      type: req,
      dataType: "json",
      data: data,
//      success: function(files,data,xhr) { 
//        document.getElementById('if_priponkas').contentDocument.location.reload(true); 
//      }
      success: function(data) {
        process_json_result(data);
        $('.dc-spinner').toggleClass('div-hidden');
      }
      
    });  
  }); 
    
/*******************************************************************
  will open a new window with URL specified. 
********************************************************************/
  $('.dc-window-open').on('click', function(e) { 
    var url   = this.getAttribute("data-url");
    var title = this.getAttribute("title");
    var w     = 1000;
    var h     = 800;
    var left  = (screen.width/2)-(w/2);
    var top   = (screen.height/2)-(h/2);
    var win   = window.open(url, title, 'toolbar=no, location=no, directories=no, status=no, menubar=no, scrollbars=yes, resizable=no, copyhistory=no, width='+w+', height='+h+', top='+top+', left='+left);
    win.focus();
//    $('#bpopup').bPopup({ loadUrl: url, speed: 650, transition: 'slideDown' });  
  });  

 /*******************************************************************
 * Animate button on click
 ******************************************************************
  $('.xdc-action-menu li').mousedown( function() {
    $(this).toggleClass('dc-animate-button');
  });
  
 ******************************************************************
 * Animate button on click
 ******************************************************************
  $('.xdc-action-menu li').mouseup( function() {
    $(this).toggleClass('dc-animate-button'); 
  });
 */
 /*******************************************************************
 * Animate button on click
 *******************************************************************/
  $('.dc-animate').mousedown( function() {
    $(this).toggleClass('dc-animate-button');
  });
  
 /*******************************************************************
 * Animate button on click
 *******************************************************************/
  $('.dc-animate').mouseup( function() {
    $(this).toggleClass('dc-animate-button'); 
  });
 
 /*******************************************************************
  * App menu option clicked
  *******************************************************************/
  $('.app-menu-item a').on('click', function(e) { 
/* parent of a is li */
    $(e.target).parents('li').each( function() {
/* for all li's in ul, deselect */
      $(this).parents('ul').find('li').each( function() {
        if ($(this).hasClass('app-menu-item-selected')) {
          $(this).toggleClass('app-menu-item-selected');
        }
      });
/* select clicked li */
      $(this).toggleClass('app-menu-item-selected');
    });
  });

/*******************************************************************
 * Display spinner on link with spinner, submit link
 *******************************************************************/
  $('.dc-link-spinner').on('click', function(e) {
    $('.dc-spinner').toggleClass('div-hidden');
  });  
  
  $('.dc-link-submit').on('click', function(e) {
    $('.dc-spinner').toggleClass('div-hidden');
  });  

/*******************************************************************
  * Add button clicked while in edit. Create window dialog for adding new record
  * into required table. This is helper scenario, when user is selecting
  * data from with text_autocomplete and data doesn't exist in belongs_to table.
  *******************************************************************/
  $('.in-edit-add').on('click', function(e) { 
    url = '/cmsedit/new?table=' + this.getAttribute("data-table");
/* I know. It doesn't work as expected. But it will do for now. */
    w = window.open(url, '', 'chrome=yes,width=800,height=600,resizable,scrollbars=yes,status=1,centerscreen=yes,modal=yes');
    w.focus();    
  });  
  
/**********************************************************************
 * When filter_field (field name) is selected on filter subform this routine finds 
 * and displays apropriate span with input field.
 **********************************************************************/
  $('#filter_field').on('change', function() {
    if (this.value.length > 0) { 
      name = 'filter_' + this.value;
      $(this).parents('form').find('span').each( function() {
/*
element = $(this).find(':first').attr('id');
 sometimes it is the second element         
        if (element == nil) { element = $(this).find(':first').next().attr('id');}
 */   
        if ($(this).attr('id') == name) {
          if ( $(this).hasClass('div-hidden') ) { $(this).toggleClass('div-hidden'); }
        } else {
          if ( !$(this).hasClass('div-hidden') ) { $(this).toggleClass('div-hidden'); }
        }
      });         
    } 
  });

/*******************************************************************
 * It is not possible to attach any data to submit button except the text
 * that is written on a button and it is therefore very hard to distinguish
 * which button was pressed when more than one button is present on a form.
 * 
 * The purpose of this trigger is to append data hidden in html5 data attributes
 * to the form. We can now attach  any kind of data to submit button and data 
 * will be passed as data[] parameters to controller. 
 *******************************************************************/
  $('.dc-submit').on('click', function() {
    $.each(this.attributes, function() {
      if (this.name.substring(0,5) == 'data-') { 
        $('<input>').attr({
          type: 'hidden',
          name: 'data[' + this.name.substring(5) + ']',
          value: this.value
        }).appendTo('form');
      }
    });
  });
 
 /* DOCUMENT INFO                                                   */ 
 /*******************************************************************
  * Popup or hide document information 
  *******************************************************************/
  $('#dc-document-info').on('click',function(e) { 
    popup = $('#dc-document-info-popup');
    popup.toggleClass('div-hidden'); 
    if (!popup.hasClass('div-hidden')) {
      var o = {
        left: e.pageX - popup.width() - 10,
        top: e.pageY - popup.height() - 20
      };
      popup.offset(o);    
    };
  });
 /*******************************************************************
  * Just hide document information on click.
  *******************************************************************/
  $('#dc-document-info-popup').on('click',function(e) {
    $('#dc-document-info-popup').toggleClass('div-hidden'); 
  });    

/*******************************************************************
 * Experimental. Force reload of parent page if this div appears. 
 *******************************************************************/
  $('#div-reload-parent').on('load', function() {
//    alert('div-reload-parent 1');
    parent.location.href = parent.location.href;
  });

/*******************************************************************
 * Force reload of parent page if this div appears. 
 * 
 * Just an Idea. Not needed yet.
 *******************************************************************/
  $('#div-reload').on('load', function() {
    alert('div-reload 1');
//    location.href = location.href;
  });
  
  $('#div-reload-parent').on('DOMNodeInserted DOMNodeRemoved', function() {
    alert('div-reload-parent 2');
  });  
  $('#div-reload').on('DOMNodeInserted DOMNodeRemoved', function() {
    alert('div-reload 2');
  });
  
 /*******************************************************************
  * Fire action (by default show document) when doubleclicked on result row
  *******************************************************************/
  $('.dc-result tr').on('dblclick', function(e) {
    url = String( this.getAttribute("data-dblclick") );
// prevent when data-dblclick not set
    if (url.length > 5) { 
      e.preventDefault();
      location.href = url;
    } 
  });
  
  /*******************************************************************
  * Fire action (by default show document) when doubleclicked on result row
  *******************************************************************/
  $('.dc-result-data').on('dblclick', function(e) {
    url = String( this.getAttribute("data-dblclick") );
// prevent when data-dblclick not set
    if (url.length > 5) { 
      e.preventDefault();
      location.href = url;
    } 
  });

 /*******************************************************************
  * Fire action clicked on result row. 
  * TODO: Find out how to prevent event when clicked on action icon.
  *******************************************************************/
  $('.dc-result tr').on('click', function(e) {
    url = String( this.getAttribute("data-click") );
// prevent when data-click not set
    if (url.length > 5) { 
      e.preventDefault();
      location.href = url; 
    } 
  });

 $('#1menu-filter').on('click', function(e) {
    var target = e.target;
//    if (e.target.src !== undefined) {
//      target = e.target.parent(); // picture
//    };
//    dumpAttributes(target);
    req = target.getAttribute("data-request");
    $('.menu-filter').toggle(300);
    
  });
  
 /*******************************************************************
  * This will fire cmsedit index action and pass value enterred into 
  * filter field and thus refresh browsed result set.
  *******************************************************************/
  $('#_record__filter_field').keydown( function(e) {
    if (e.which == '13' || e.which == '9') {
      url = $(this).parents('span').attr("data-url");
      url = url + "&filter_value=" + this.value;
      location.href = url;
      return false;      
    }
  });

  /*******************************************************************
  * Same as above, but when clicked on filter icon. enter and tab don't 
  * work on all field types.
  *******************************************************************/
  $('.record_filter_field_icon').on('click', function(e) {
    field = $('#_record__filter_field');
    url = $(this).parents('span').attr("data-url");
    url = url + "&filter_value=" + field.val();
    location.href = url;
  });

 /*******************************************************************
  * Click on show filter form
  *******************************************************************/
  $('#open_drgcms_filter').on('click', function(e) {
    $('#drgcms_filter').bPopup({
      speed: 650,
      transition: 'slideDown'
    });      
  });
  
  /*******************************************************************
  * Click on preview selected image
  *******************************************************************/
  $('.dc-image-preview').on('click', function(e) {
//      var img = $('.img1 img').attr('src');
      var img = $(this).children(":first").attr('src');
      $('#dc-image-preview').bPopup({
            content:'image', //'ajax', 'iframe' or 'image'
            contentContainer:'#dc-image-preview',
            loadUrl: img
        });
  });
  
 /*******************************************************************
  * 
  *******************************************************************/
  $('.drgcms_popup_submit').on('click', function(e) {
    //e.preventDefault();  
    url = $(this).attr( 'data-url' );
    field = $('select#filter_field1').val();
    oper  = $('select#filter_oper').val();
    location.href = url + '&filter_field=' + field + '&filter_oper=' + oper
// Still opening in new window
//    iframe = parent.document.getElementsByTagName("iframe")[0].getAttribute("id");
//    loc = url + '&filter_field=' + field + '&filter_oper=' + oper
//    $('#'+iframe).attr('src', loc);
//    parent.document.getElementById(iframe).src = loc   
   });
   
 /*******************************************************************
  * Toggle one cmsedit menu level
  *******************************************************************/
   $('.cmsedit-top-level-menu').on('click', function(e) {
     $(e.target).find('ul').toggle('fast');
   });
   
/*******************************************************************
  * Resize result table columns. For now an idea.
  *******************************************************************/
 /*
   $( ".dc-result-header .spacer" )
  .mouseenter(function() {
    console.log("enter");
  })
  .mouseleave(function() {
    console.log("leave");
  });
*/  
 /*******************************************************************
  * number_field type entered
  *******************************************************************/
   $('.dc-number').on('focus', function(e) {
    var separator = $(this).attr("data-separator") || ',';
    var field = '#' + $(this).attr("id").slice(0,-1);
    var value = $(field).val().replace('.',separator);
    $(this).val( value );
    $(this).select();
   });

  /*******************************************************************
  * number_field type leaved
  *******************************************************************/
   $('.dc-number').on('focusout', function(e) {
//     format_number_field($(this));
     
     var decimals  = $(this).attr("data-decimal") || 2;
     var delimiter = $(this).attr("data-delimiter") || '.';
     var separator = $(this).attr("data-separator") || ',';
     var currency  = $(this).attr("data-currency") || '';
     var whole = this.value.split(separator)[0];
     var dec   = this.value.split(separator)[1];
// save value to hidden field which will be used for return 
     var field = '#' + $(this).attr("id").slice(0,-1);
     var value = this.value.replace(separator,'.');
// remove negative sign and add at the end
     var sign = whole.substr(0,1);
     if (sign == '-') { 
       whole = whole.substr(1,20);
     } else { 
       sign = '';
     }
    
     $(field).val( parseFloat(value).toFixed(decimals) );
     
// decimal part
     if (dec == null) dec = '';
     dec = dec.substring(0, decimals, dec);
     while (dec.length < decimals) dec = dec + '0';
// whole part 
     if (whole == null || whole == '') whole = '0';
     var ar = [];
     while (whole.length > 0) { 
       var pos1 = whole.length - 3
       if (pos1 < 0) pos1 = 0;
       ar.unshift(whole.substr(pos1,3)); 
       whole = whole.slice(0, -3); 
     };
          
     if (delimiter !== '') whole = ar.join(delimiter);
     $(this).val(sign + whole + separator + dec + currency);
   });
   
 /*******************************************************************
  * number_field type keypressed
  *******************************************************************/
   $('.dc-number').on('keydown', function(e) {
// Minus sign. Put it on first place     
     if (e.which == 109) {
       if($(this).val().substr(0,1) == '-') {
         $(this).val( $(this).val().substr(1,20));
       } else {
         $(this).val( '-' + $(this).val());
       }
       e.preventDefault();
     }
// Enter. Save value before Enter is processed
      if (e.which == 13) {
        var delimiter = $(this).attr("data-delimiter") || '.';
        var decimals  = $(this).attr("data-decimal") || 2;        
        var value = $(this).val().replace(delimiter,'.');
        var field = '#' + $(this).attr("id").slice(0,-1);
        
        $(field).val( parseFloat(value).toFixed(decimals) );
      }
   });
   
 /*******************************************************************
  * Result header sort icon is hoverd. Change background icon to filter.
  *******************************************************************/
  $('.dc-result-header .th i').hover( function() {
    old_sort_icon = '';
    // save old sort icon and replace it with filter icon   
    $.each( $(this).attr("class").split(/\s+/), 
      function(index, item) { if (item.match('sort')) { old_sort_icon = item}; }
    );
    $(this).removeClass(old_sort_icon).addClass('fa-filter');
// bring back old sort icon
  }, function(){
    $(this).removeClass('fa-filter').addClass(old_sort_icon);
  });

/*******************************************************************
  * Result header sort icon is clicked. Display filter menu for the field.
  *******************************************************************/
  $('.dc-result-header .th i').click( function(e) {
    e.preventDefault();
    // additional click will close dialog when visible
    if ($('.filter-popup').is(':visible')) {
      $('.filter-popup').hide();
      return;
    }
    // retrieve name of current field and set it in popup
    var header = $(this).closest('.th');
    var field_name = header.attr("data-name");    
    $('.filter-popup').attr('data-name', field_name);
    // change popup position and show
    $('.filter-popup').css({'top':e.pageY+5,'left':e.pageX, 'position':'absolute'});
    $('.filter-popup').show();    
  });
  
/*******************************************************************
  * Filter operation is clicked on filter popup. Retrieve data and call
  * filter on action.
  *******************************************************************/
  $('.filter-popup li').click( function(e) {
    var url      = $(this).data('url')
    var operator = $(this).data('operator');
    var parent   = $(this).closest('.filter-popup')
    var field_name = parent.data("name");
    
    url = url + '&filter_field=' + field_name + '&filter_oper=' + operator;
    console.log(url);
    window.location.href = url;
  });

});

/*******************************************************************
 * Catch ctrl+s key pressed and fire save form event. I press ctrl+s
 * almost every minute. That was a lesson learned years ago when I lost
 * few hours of work on computer lockup ;-(
 *******************************************************************/
$(document).keydown( function(e) {
  if ((e.which == '115' || e.which == '83' ) && (e.ctrlKey || e.metaKey))
  {
    e.preventDefault();
    document.forms[0].submit();
    return false;
  }
  return true;
});

/*******************************************************************

 *******************************************************************
$(document).onmousedown( function(e) {
  mouseDown = true;
  console.log("mouse down");  
});

$(document).onmouseup( function(e) {
  mouseDown = false;
  console.log("mouse up");  
});

**/