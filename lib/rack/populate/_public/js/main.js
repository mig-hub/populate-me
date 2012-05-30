$(function() {
  // init
  var template_nutshell = $('#template-nutshell').html();
  var template_nut_tree = $('#template-nut-tree').html();
  
  $.get('/admin/list/Project', function(data) {
    $('#content').html($.mustache(template_nut_tree, data, {nutshell: template_nutshell}));
  });
});

