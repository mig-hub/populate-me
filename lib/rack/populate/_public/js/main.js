// Array last()
Array.prototype.last = function() {
  return this[this.length-1];
};

$(function() {
  // Templates
  var template_menu = $('#template-menu').html();
  var template_nutshell = $('#template-nutshell').html();
  var template_nut_tree = $('#template-nut-tree').html();
  
  // Content div
  var $content = $('#content');
  var content_callback = function() {
    // Cancel form
    $(':submit[value=SAVE]').after(" or <a href='javascript:;' class='popstack cancel'>CANCEL</a>");
  };
  var load_content_from = function(url) {
    $.get(url, function(data) {
      if (typeof(data)=='string') $content.html(data);
      if (data.action=='menu') $content.html($.mustache(template_menu, data));
      if (data.action=='list') $content.html($.mustache(template_nut_tree, data, {nutshell: template_nutshell}));
      content_callback();
    });
  };

  // Stack
  // For each step, the stack record an object with the new URL and other values like scroll
  var stack = [];
  var pushstack = function(url) {
    if(!stack.length==0) stack.last().scroll = $(window).scrollTop(); // record state
    stack.push({url: url});
    load_content_from(url);
  };
  var popstack = function() {
    if(stack.length>1) {
      stack.pop();
      load_content_from(stack.last().url);
      $(window).scrollTop(stack.last().scroll);// reset previous state
    }
  };
  
  // Stack links
  $(".pushstack").live('click', function() {
    pushstack(this.href);
    return false;
  });
  $(".popstack").live('click', function() {
    popstack();
    return false;
  });
  
  // Ajax form
  $('.backend-form').live('submit', function() {
		var $form = $(this);
		$form.find(':submit').after("<img src='"+admin_path+"/_public/img/small-loader.gif' />").remove();
		$form.ajaxSubmit({
			success: function(data) {
				if (data.match(/OK/)) { // Success
					popstack();
				} else {
					$content.html(data);
					content_callback();
				}
			}
		});
		return false;
	});

  // Init
  pushstack(admin_path+'/menu');
});

