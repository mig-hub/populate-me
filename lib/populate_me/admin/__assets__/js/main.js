$(function() {
  var init_new_column = function(c) {
    // Ajax delete
    $('button.admin-delete',c).click(function(e) {
      var self = $(this);
      e.preventDefault();
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
  };
  var finder = $('#finder');
  finder.columnav({
    on_push: function(data) {
      init_new_column(data.column);
    }
  });  
  init_new_column(finder.find('> li:first'));
});

