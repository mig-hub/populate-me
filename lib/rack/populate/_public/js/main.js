// Array last()
Array.prototype.last = function() {
  return this[this.length-1];
};

$(function() {
  // Templates
  var template_menu = $('#template-menu').html();
  var template_nutshell = $('#template-nutshell').html();
  var template_nut_tree = $('#template-nut-tree').html();
  
  // Stack
  // For each step, the stack record an object with the new URL and other values like scroll
  var stack = [];
  var pushstack = function(url) {
    if(stack.length!=0) { // record state
      stack.last().scroll = $(window).scrollTop();
      stack.last().search = $search.val();
      $search.val('');
    }
    stack.push({url: url});
    load_content_from(url);
  };
  var popstack = function() {
    if(stack.length>1) {
      stack.pop();
      load_content_from(stack.last().url, true);
    }
  };
  
  // Quicksearch
  var $search = $('#search');
  var search_opts = {
    onAfter: function() {
      if ($search.val()=='' && stack.length!=0 && stack.last().sortable) {
        $('.nutshell-bar').addClass('sortable-handle');
      } else {
        $('.nutshell-bar').removeClass('sortable-handle');
      }
    }
  }
  var qs;
  
  // Content div
  var $content = $('#content');
  var $page_title = $('#page-title');
  var content_callback = function() {
    // Cancel form
    $(':submit[value=SAVE]').after(" or <a href='javascript:;' class='popstack cancel'>CANCEL</a>");
    // reset previous state
    $search.val(stack.last().search);
    $('#search').keyup();
    $(window).scrollTop(stack.last().scroll);
    // Sortable
    $('.sortable').sortable({
      stop: function() { $.ajax({
        url: admin_path+'/'+stack.last().class_name, 
        data: $(this).sortable('serialize'),
        type: 'PUT'
      });
      },
      items: '.nutshell',
      handle:'.sortable-handle'
    });
    // Date/Time pickers
    $('.datepicker').datepicker({dateFormat: 'yy-mm-dd'});
    $('.timepicker').timepicker({showSecond: true,timeFormat: 'hh:mm:ss'});
    $('.datetimepicker').datetimepicker({showSecond: true,dateFormat: 'yy-mm-dd',timeFormat: 'hh:mm:ss'});
    // Multiple select with asmSelect
    $(".asm-select").asmSelect({ sortable: true });
  };
  var load_content_from = function(url, poping) {
    $.get(url, function(data) {
      var query_string = url.match(/\?.*$/);
      data.query_string = query_string ? query_string[0].replace(/filter\[/g,'model[') : '';
      var direction = poping ? '200px' : '-200px';
      $content.animate({left: direction, opacity: 0}, function() {
        $content.css({left: '0px'});
        if (data.action=='form') $content.html(data.form);
        if (data.action=='menu') $content.html($.mustache(template_menu, data));
        if (data.action=='list') {
          $content.html($.mustache(template_nut_tree, data, {nutshell: template_nutshell}));
          stack.last().class_name = data.class_name
          stack.last().sortable = data.sortable
          qs = $search.quicksearch($(".nutshell"), search_opts);
        }
        content_callback();
        $page_title.html(data.page_title);
        $content.animate({opacity: 1});
      });
    });
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
        if (data.action=='save') { // Success
          popstack();
        } else {
          $content.html(data.form);
          content_callback();
        }
      }
    });
    return false;
  });
  
  // Ajax delete
  $('.nutshell-delete').live('click', function() {
    var $this = $(this);
    if (confirm('Are you sure you want to delete this ?')) {
      $.ajax({
        url: this.href, 
        type: 'DELETE',
        success: function() { $this.parents('.nutshell').fadeOut(function() { $(this).remove(); }); }
      });
    }
    return false;
  });

  // Init
  pushstack(admin_path+'/menu');
});

