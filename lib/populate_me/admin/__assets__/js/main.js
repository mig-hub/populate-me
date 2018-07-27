// Namespace
var PopulateMe = {};

// Returns a Mustache template from either
// the dom element itself, or the id of the dom element.
PopulateMe.init_template = function(obj_or_id) {
  var obj = (typeof obj_or_id == 'object') ? obj_or_id : $(obj_or_id);
  var template = obj.html();
  Mustache.parse(template);
  return template;
};

// Output a legible version of the size in bytes.
// 1024 => "1KB"
// 2097152 => "2MB"
PopulateMe.display_file_size = function(size) {
  var unit = 'B';
  if (size>1024) {
    size = size / 1024;
    unit = 'KB';
  }
  if (size>1024) {
    size = size / 1024;
    unit = 'MB';
  }
  if (size>1024) {
    size = size / 1024;
    unit = 'GB';
  }
  return size+unit;
};

// Add or update query string parameter on a URI
PopulateMe.update_query_parameter = function(uri, key, value) {
  var sane_key = key.replace(/[\[\]]/g, "\\$&");
  var re = new RegExp("([?&])" + sane_key + "=.*?(&|$)", "i");
  var separator = uri.indexOf('?') !== -1 ? "&" : "?";
  if (uri.match(re)) {
    return uri.replace(re, '$1' + key + "=" + encodeURIComponent(value) + '$2');
  }
  else {
    return uri + separator + key + "=" + encodeURIComponent(value);
  }
};

// Template helpers
PopulateMe.template_helpers = {
  custom_partial_or_default: function() {
    return function(text,render) {
      return render('{{>'+(this.custom_template||text)+'}}');
    }
  },
  adapted_field: function() {
    return function(text,render) {
      var tmpl;
      if (this.custom_template) {
        tmpl = this.custom_template;
      } else {
        tmpl = 'template_'+this.type+'_field';
        if (!(tmpl in PopulateMe.templates)) tmpl = 'template_string_field';
      }
      return render('{{>'+tmpl+'}}');
    }
  },
  build_input_attributes: function() {
    var out = "";
    $.each(this.input_attributes, function(k,v) {
      if (v!==false) {
        out = out+' '+k;
        if (v!==true) out = out+'=\''+Mustache.escape(v)+'\'';
      }
    });
    return out;
  },
  cache_buster: function() {
    // Simple version which assumes the url has no query yet or hash
    var buster = Math.random()*10000000000000000;
    return '?cache_buster='+buster;
  }
};

// Template render with helpers
PopulateMe.mustache_render = function(data) {
  var data_and_helpers = $.extend(data,PopulateMe.template_helpers);
  return Mustache.render(PopulateMe.templates[data.template],data_and_helpers,PopulateMe.templates);
};

// Make Sortable from element or css selector
PopulateMe.make_sortable = function(selector,context) {
  var obj = (typeof selector == 'string') ? $(selector,context) : selector;
  return obj.sortable({
    forcePlaceholderSize: true,
    handle: '.handle'
  });
};

// Scroll to an element, possibly in a specific column.
PopulateMe.scroll_to = function(el, column) {
  if (!column) {
    column = el.closest('.column');
  }
  column.animate({scrollTop: el.position().top});
};

// Mark errors for report after form validation.
// It adds the .invalid class to invalid fields,
// and adds the report after the label of the field.
PopulateMe.mark_errors = function(context,report) {
  $.each(report,function(k,v) {
    var field = context.find('> [data-field-name='+k+']:first');
    if (field.is('fieldset')) {
      $.each(v, function(index,subreport) {
        var subcontext = field.find('> .nested-documents > li:nth('+index+')');
        PopulateMe.mark_errors(subcontext, subreport);
      });
    } else {
      field.addClass('invalid');
      var errors = "<span class='errors'>, "+v.join(', ')+"</span>";
      field.find('> label').append(errors);
    }
  });
};

// JS Validations
// This adds validations that could happen before sending
// anything to the server and that cannot be done with 
// browser form validations like "required".
// For example we can check the file size so that files are not sent
// to the server at all if they are too big.
// Returns a boolean.
PopulateMe.jsValidationsPassed = function(context) {
  if (window.File && window.FileReader && window.FileList && window.Blob) {
    try {
      var max_size_fields = $('input[type=file][data-max-size]', context);
      max_size_fields.each(function() {
        var field = $(this);
        var max_size = parseInt(field.data('max-size'));
        if (field[0].files[0]) {
          var fsize = field[0].files[0].size;
          var fname = field[0].files[0].name;
          if (fsize>max_size) {
            alert('File too big: '+fname+' should be less than '+PopulateMe.display_file_size(max_size)+'.');
            throw "Validation error";
          }
        }
      });
    } catch(e) {
      if (e==='Validation error') { 
        return false;
      } else {
        throw(e);
      }
    }
  }
  return true;
};

// Init column 
// Bind events and init things that need to happen when 
// a new column is added to the finder.
// The callback `custom_init_column` is also called at the end
// in case you have things to put in your custom javascript.
PopulateMe.init_column = function(c) {

  // Sort list item
  PopulateMe.make_sortable('.documents',c).bind('sortupdate', function(e, ui) {
    var list = $(ui.item).closest('.documents');
    var ids = list.children().map(function() {
      return $(this).data().id;
    }).get();
    $.ajax({
      url: list.data().sortUrl,
      type: 'put',
      data: {
        action: 'sort',
        field: list.data().sortField,
        ids: ids
      }
    });
    /*
    ui.item contains the current dragged element.
    ui.item.index() contains the new index of the dragged element
    ui.oldindex contains the old index of the dragged element
    ui.startparent contains the element that the dragged item comes from
    ui.endparent contains the element that the dragged item was added to
    */
  });

  // Sort nested documents
  PopulateMe.make_sortable('.nested-documents',c);

  // Init textareas
  $('textarea',c).trigger('input');

  // Init multiple select with asmSelect
  $('select[multiple]', c).asmSelect({ sortable: true, removeLabel: '&times;' });

  // Polymorphic selector
  $('select.polymorphic_type_values').change(function() {
    var $this = $(this);
    var link = $this.next();
    link.attr('href', PopulateMe.update_query_parameter(link.attr('href'), 'data[polymorphic_type]', $this.val()));
  }).change();

  // Possible callback from custom javascript file.
  // If you need to do something on init_column,
  // create this callback.
  if (PopulateMe.custom_init_column) {
    PopulateMe.custom_init_column(c);
  }

}; // End - Init column



// Dom ready
$(function() {

  // Dom elements.
  PopulateMe.finder = $('#finder');

  // Init templates
  PopulateMe.templates = {};
  $('[type=x-tmpl-mustache]').each(function() {
    var $this = $(this);
    PopulateMe.templates[$this.attr('id').replace(/-/g,'_')] = PopulateMe.init_template($this);
  });

  // Reactive text area
  // It switches between online or longer depending on the amount 
  // of text.
  // Long term, for this reason, it might be used for both
  // :string and :text fields.
  $('body').on('input propertychange', 'textarea', function() {
    if (this.value.length>50 || this.value.match(/\n/)) {
      $(this).removeClass('oneline');
    } else {
      $(this).addClass('oneline');
    }
  });

  // Ajax form
  $('body').on('submit','form.admin-post, form.admin-put', function(e) {
    e.preventDefault();
    var self = $(this);
    if (PopulateMe.jsValidationsPassed(self)) {

      var submit_button = $('input[type=submit]',self);
      submit_button.hide();
      $.ajax({
        url: self.attr('action'),
        type: (self.is('.admin-put') ? 'put' : 'post'),
        data: new FormData(this),
        processData: false,
        contentType: false,
        success: function(res) {
          if (res.success==true) {
            var reloader = PopulateMe.finder.find('> li:nth-last-child(3) .selected')
            if (reloader.size()>0) {
              reloader.trigger('click.columnav',[function(cb_object) {
                var target = $('[data-id='+res.data.id+']', cb_object.column);
                if (target.size()>0) {
                  PopulateMe.scroll_to(target, cb_object.column);
                }
              }]);
            } else {
              PopulateMe.finder.trigger('pop.columnav');
            }
          }
        },
        error: function(xhr) {
          res = xhr.responseJSON;
          if (res.success==false) {
            $('.invalid',self).removeClass('invalid');
            $('.errors',self).remove();
            PopulateMe.mark_errors(self,res.data);
            PopulateMe.scroll_to(self.find('.invalid:first'));
            submit_button.show();
          }
        }
      });

    }
  });

  // Create nested document
  $('body').on('click','.new-nested-document-btn', function(e) {
    e.preventDefault();
    var self = $(this);
    $.get(this.href, function(data) {
      var content = $(PopulateMe.mustache_render(data));
      PopulateMe.make_sortable(self.closest('fieldset').find('> ol').append(content).sortable('destroy'));
      PopulateMe.scroll_to(content);
    });
  });

  // Ajax delete document
  $('body').on('click', 'button.admin-delete', function(e) {
    e.preventDefault();
    var self = $(this);
    if (confirm('Are you sure you want to delete this item? This operation is not reversible.')) {
      $.ajax({
        url: self.val(),
        type: 'DELETE',
        success: function() { 
          var li = self.parents('li.admin-list-item');
          li.fadeOut(function() {
            li.remove();
          }); 
        }
      });
    }
  });

  // Ajax delete nested document
  $('body').on('click', 'button.admin-delete-nested', function(e) {
    e.preventDefault();
    var self = $(this);
    if (confirm('Are you sure you want to delete this item? This operation is not reversible.')) {
      var li = self.closest('li');
      li.fadeOut(function() {
        li.remove();
      }); 
    }
  });

  // Attachment deleter
  $('body').on('click', 'button.attachment-deleter', function(e) {
    e.preventDefault();
    var self = $(this);
    var input = self.parent().find('input');
    if (input.attr('type')=='file') {
      alert('The attachment will be deleted when you save the document.');
      input.attr('type','hidden').val('');
      self.text('Cancel attachment deletion');
    } else {
      input.attr('type','file');
      self.text('x');
    }
  });

  // Init finder
  PopulateMe.finder.columnav({
    on_push: function(data) {
      PopulateMe.init_column(data.column);
    },
    process_data: function(data) {
      if (typeof data == 'object') {
        return PopulateMe.mustache_render(data);
      } else {
        return data;
      }
    }
  });  
  PopulateMe.finder.trigger('getandpush.columnav',[window.admin_path+window.index_path]);

}); // End - DomReady

