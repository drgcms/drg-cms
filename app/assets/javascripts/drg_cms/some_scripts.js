
// facebook recommend button                                                    
$(function() {
  likebutton = '<fb:like href="" send="" width="100" show_faces="" ' +
               'font="" layout="button_count" action="recommend">' +
               '</fb:like>';
  $.getScript('http://connect.facebook.net/sl_SI/all.js', function() {
    FB.init({   status: true,
// appId: 141936272547391,                  
    cookie: true,
    xfbml: true
    });
    $('#facebook').replaceWith(likebutton);
  });
});



 /*******************************************************************
  * This is realy dirty hack, because firefox doesn't show ckeditor properly if on hidden id.
  * Not working. Left as reminder. Newer version of ck_editor helped.
  *******************************************************************/
/*
  $(".dc-form-li").each(function() {
      if (!$(this).hasClass('dc-form-li-selected')) {
        attr = $(this).context.attributes[1].nodeValue
        alert(attr);
        console.log($(this));
        $('#data_' + attr).toggleClass('div_hidden'); 
      }
    });  
*/

