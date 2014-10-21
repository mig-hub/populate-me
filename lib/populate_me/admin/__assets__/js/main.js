var init_template = function(obj_or_id) {
  var obj = (typeof obj_or_id == 'object') ? obj_or_id : $(obj_or_id);
  var template = obj.html();
  Mustache.parse(template);
  return template;
};

$(function() {

  // Vars
  var finder = $('#finder');

  // Init templates
  var templates = {};
  $('[type=x-tmpl-mustache]').each(function() {
    var $this = $(this);
    templates[$this.attr('id').replace(/-/g,'_')] = init_template($this);
  });

  // Init column 
  var init_column = function(c) {

    // Ajax delete
    $('button.admin-delete',c).click(function(e) {
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
        })
      }
    });

    // Ajax form
    $('form.admin-post, form.admin-put',c).submit(function(e) {
      e.preventDefault();
      var self = $(this);
      $.ajax({
        url: self.attr('action'),
        type: (self.is('.admin-put') ? 'put' : 'post'),
        data: new FormData(this),
        processData: false,
        contentType: false,
        success: function(res) {
          if (res.success==true) {
            finder.find('> li:nth-last-child(3) .selected').trigger('click.columnav',[function(cb_object) {
              var target = $('.'+res.data['_class']+'-'+res.data.id);
              if (target.size()>0) {
                cb_object.column.animate({scrollTop: target.position().top});
              }
            }]);
          }
        }
      })
    });

    // Sort list item
    $('.documents',c).sortable({
      forcePlaceholderSize: true
    }).bind('sortupdate', function(e, ui) {
      /*
      This event is triggered when the user stopped sorting and the DOM position has changed.
      ui.item contains the current dragged element.
      ui.item.index() contains the new index of the dragged element
      ui.oldindex contains the old index of the dragged element
      ui.startparent contains the element that the dragged item comes from
      ui.endparent contains the element that the dragged item was added to
      */
    });

  }; // End - Init column

  // Init finder
  finder.columnav({
    on_push: function(data) {
      init_column(data.column);
    },
    process_data: function(data) {
      if (typeof data == 'object') {
        return Mustache.render(templates[data.template],data,templates);
      } else {
        return data;
      }
    }
  });  
  finder.trigger('getandpush.columnav',[window.admin_path+window.index_path]);

}); // End - DomReady

