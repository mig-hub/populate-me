// For each step, the stack record an object with the new URL and other values like scroll
var stack = [];

$(function() {
  // init
  var template_nutshell = $('#template-nutshell').html();
  var template_nut_tree = $('#template-nut-tree').html();

  
  
  $.get('/admin/menu', function(data) {
    $('#content').html($.mustache(template_nut_tree, data, {nutshell: template_nutshell}));
  });
});

