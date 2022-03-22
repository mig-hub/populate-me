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

// Copy and restore column search.
// Used when saving pops the columns.
PopulateMe.copy_column_search = function(column) {
  return column.find('.search-items').val();
};
PopulateMe.restore_column_search = function(column, value) {
  if (value !== '' && column.data('qs')) {
    column.find('.search-items').val(value);
    column.data('qs').search(value);
  }
};

// Scroll to an element, possibly in a specific column.
PopulateMe.scroll_to = function(el, column) {
  if (!column) {
    column = el.closest('.column');
  }
  el.get(0).scrollIntoView({ behavior: 'smooth'});
};

// Mark errors for report after form validation.
// It adds the .invalid class to invalid fields,
// and adds the report after the label of the field.
PopulateMe.mark_errors = function(context, report, isSubcontext) {
  if (!isSubcontext) {
    $('.invalid', context).removeClass('invalid');
    $('.errors', context).remove();
  }
  $.each(report,function(k,v) {
    var field = context.find('> [data-field-name='+k+']:first');
    if (field.is('fieldset')) {
      $.each(v, function(index,subreport) {
        var subcontext = field.find('> .nested-documents > li:nth('+index+')');
        PopulateMe.mark_errors(subcontext, subreport, true);
      });
    } else {
      field.addClass('invalid');
      var errors = "<span class='errors'>, "+v.join(', ')+"</span>";
      field.find('> label').append(errors);
    }
  });
};

// Navigate columns back
PopulateMe.navigate_back = function(target_id) {
  // !!! Careful, it only works if we call this from the last column
  var reloader = PopulateMe.finder.find('> li:nth-last-child(3) .selected');
  if (reloader.size() > 0) {
    var reloadee = PopulateMe.finder.find('> li:nth-last-child(2)');
    var current_search = PopulateMe.copy_column_search(reloadee);
    reloader.trigger('click.columnav',[function(cb_object) {
      PopulateMe.restore_column_search(cb_object.column, current_search);
      if (target_id) {
        var target = $('[data-id=' + target_id + ']', cb_object.column);
        if (target.size() > 0) {
          PopulateMe.scroll_to(target, cb_object.column);
        }
      }
    }]);
  } else {
    PopulateMe.finder.trigger('pop.columnav');
  }
}

PopulateMe.fieldMaxSize = function(field) {
  var maxSizeData = field.data('max-size');
  if (!maxSizeData) {
    return null;
  }
  return field.data('max-size');
};

PopulateMe.fieldHasFileTooBig = function(field, maybeFile) {
  var file = maybeFile || field[0].files[0];
  if (!file) {
    return false;
  }
  var maxSize = PopulateMe.fieldMaxSize(field);
  if (!maxSize) {
    return false;
  }
  return file.size > maxSize;
};

PopulateMe.fileTooBigErrorMessage = function(fname, max_size) {
  if (typeof max_size != 'number') {
    max_size = PopulateMe.fieldMaxSize(max_size);
  }
  return 'File too big: ' + fname + ' should be less than ' + PopulateMe.display_file_size(max_size) + '.';
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
        if (PopulateMe.fieldHasFileTooBig(field)) {
          alert(PopulateMe.fileTooBigErrorMessage(file.name, field));
          throw "Validation error";
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

  var documents = $('.documents', c); 

  // Sort list item
  if (documents.data('sort-field') !== '') {
    PopulateMe.make_sortable(documents).bind('sortupdate', function(e, ui) {
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
  }

  // Sort nested documents
  PopulateMe.make_sortable('.nested-documents',c);

  $('.search-items', c).each(function() {
    var field = $(this)
    var qs = field.quicksearch($('.admin-list-item', c), {
      selector: '.item-title',
      onAfter: function() {
        if (documents.is('.ui-sortable')) {
          if (field.val() == '') {
            documents.sortable('enable');
          } else {
            documents.sortable('disable');
          }
        }
      }
    });
    c.data('qs', qs);
  });

  // Init textareas
  $('textarea',c).trigger('input');

  // Init multiple select with asmSelect
  $('select[multiple]', c).asmSelect({ sortable: true, removeLabel: '&times;' });

  // Select with preview
  $('select:not([multiple])', c).change(function() {
    var $this = $(this);
    var container;
    if ($this.data('preview-container')) {
      container = $($this.data('preview-container'), c);
    } else {
      container = $this.next('.preview-container');
    }
    if (container.size() == 0) return;
    var path = $this.find(':selected:first').data('preview');
    if (path) {
      var img = container.find('img:first');
      if (img.size() < 1) {
        img = $("<img src='' alt='Preview' title='Preview' width='250' />");
        container.html(img);
      }
      img.attr('src', path);
    } else {
      container.html('');
    }
  });
  $('option:selected[data-preview]').parent().change();

  // Polymorphic selector
  $('select.polymorphic_type_values').change(function() {
    var $this = $(this);
    var link = $this.next();
    link.attr('href', PopulateMe.update_query_parameter(link.attr('href'), 'data[polymorphic_type]', $this.val()));
  }).change();

  // Warning when date input not supported
  var dateFields = $('[type="date"]', c);
  if ( dateFields.size()>0 && dateFields.prop('type') != 'date' ) {
    alert('Your browser does not support date fields. You will have to enter dates manually. If you want a better experience and have a date picker, use a modern browser like Chrome.');
  }

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

  var ajaxSubmitSuccess = function(res) {
    if (res.success == true) {
      PopulateMe.navigate_back(res.data._id);
    }
  };

  var ajaxSubmitError = function(xhr, ctx) {
    res = xhr.responseJSON;
    if (res.success == false) {
      PopulateMe.mark_errors(ctx, res.data);
      PopulateMe.scroll_to(ctx.find('.invalid:first'));
      $('input[type=submit]', ctx).show();
      ctx.fadeTo("fast", 1);
    }
  };

  $('body').on('submit','form.admin-post, form.admin-put', function(e) {
    e.preventDefault();
    var self = $(this);
    self.fadeTo("fast", 0.3);
    var submit_button = $('input[type=submit]', self);
    var formData = new FormData(this);
    var batchField = self.data('batch-field');
    var batchFieldEl = $("input[name='" + batchField + "']");
    var isBatchUpload = self.is('.admin-post') &&
                        batchField &&
                        formData.getAll(batchField).length > 1;

    if (isBatchUpload) {

      if (confirm("You've selected multiple images. This will create an entry for each image. It may take a while to upload everything. Do you wish to proceed ?")) {
        submit_button.hide();
        var files = formData.getAll(batchField);
        var report = $("<div class='batch-upload-report'></div>").insertAfter(self);
        var latestSuccessfulId;
        var errorSize = 0;
        var successSize = 0;
        var addCloseButtonIfDone = function() {
          if (errorSize + successSize >= files.length) {
            var closeButton = $("<button type='button'>Close</button>").click(function(e) {
              e.preventDefault();
              PopulateMe.navigate_back();
            });
            report.append(closeButton);
          }
        };
        for (var i = 0; i < files.length; i++) {
          var file = files[i];
          if (PopulateMe.fieldHasFileTooBig(batchFieldEl, file)) {
            errorSize += 1;
            var msg = PopulateMe.fileTooBigErrorMessage(file.name, batchFieldEl);
            report.append("<div class='error'>" + msg + "</div>");
            addCloseButtonIfDone();
          } else {
            formData.set(batchField, file, file.name);
            $.ajax({
              url: self.attr('action'),
              type: (self.is('.admin-put') ? 'put' : 'post'), // Always post ?
              data: formData,
              successData: {filename: file.name, index: i+1},
              processData: false,
              contentType: false,
              success: function(res, textStatus, xhr) {
                successSize += 1;
                if (res.success == true) {
                  latestSuccessfulId = res.data._id;
                  report.append("<div>Uploaded: " + this.successData.filename + "</div>");
                }
                if (successSize >= files.length) {
                  PopulateMe.navigate_back(res.data._id);
                } else {
                  addCloseButtonIfDone();
                }
              },
              error: function(xhr, textStatus, errorThrown) {
                errorSize += 1;
                report.append("<div class='error'>Error: " + this.successData.filename + "</div>");
                res = xhr.responseJSON;
                if (res.success == false) {
                  PopulateMe.mark_errors(self, res.data);
                }
                addCloseButtonIfDone();
              }
            });
          }
        }
      }

    } else {

      if (PopulateMe.jsValidationsPassed(self)) {
        submit_button.hide();
        $.ajax({
          url: self.attr('action'),
          type: (self.is('.admin-put') ? 'put' : 'post'),
          data: formData,
          processData: false,
          contentType: false,
          success: ajaxSubmitSuccess,
          error: function(xhr, textStatus, errorThrown) {
            ajaxSubmitError(xhr, self);
          }
        });
      }

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
      } else if (typeof data == 'string' && data[0] == '{') {
        return PopulateMe.mustache_render(JSON.parse(data));
      } else {
        return data;
      }
    }
  });  
  PopulateMe.finder.trigger('getandpush.columnav',[window.admin_path+window.index_path]);

}); // End - DomReady

