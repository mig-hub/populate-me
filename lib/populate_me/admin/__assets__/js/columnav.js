(function($){

 $.fn.columnav = function(options) {

   var settings = $.extend({
     column_class: 'column',
     link_class: 'column-push',
     selected_link_class: 'selected',
     on_push: function(){},
     on_pop: function(){},
     process_data: function(data){return data;}
   }, options );

   var callback_or_default = function(callback,fallback) {
     return ((typeof callback === 'function') ? callback : fallback)
   };

   var new_column = function(el, root) {
     var $el = $(el).css({
       display: 'inline-block',
       verticalAlign: 'top',
       listStyle: 'none'
     });
     $('.'+settings.link_class, $el)
     .click(function(e) {
       $('.'+settings.link_class, $el).removeClass(settings.selected_link_class);
       var $this = $(this).addClass(settings.selected_link_class);
       var getandpush = function() {
         $.get($this.attr('href'), function(data) {
           root.trigger('push.columnav',[settings.process_data(data)]);
         });
       };
       var removable = $this.parents('.'+settings.column_class).nextAll();
       if (removable.length === 0) {
         getandpush();
       } else {
         removable.css({visibility:'hidden'})
         .animate({width:0},function(){
           if (removable.filter(':animated').length === 0) {
             removable.remove();
             getandpush();
           }
         });
       }
       e.preventDefault();
     });
   };

   return this.each(function(){
     var root = $(this).css({
       overflow: 'scroll',
       whiteSpace: 'nowrap'
     });
     root.on('push.columnav', function(e,data,cb) {
       var $data = $("<li class='"+settings.column_class+"'>"+data+"</li>");
       root.append($data);
       new_column($data, root);
       var cb_object = {event:e,column:$data,container:root};
       root.animate({scrollLeft: root.width()},function(){
         callback_or_default(cb,settings.on_push)(cb_object);
       });
     });
     root.on('pop.columnav', function(e,cb) {
       var last = root.children().last();
       last.css({visibility:'hidden'})
       .animate({width:0},function(){
         last.remove();
         var cb_object = {event:e,container:root}
         callback_or_default(cb,settings.on_pop)(cb_object);
       });
     });
     root.on('clear.columnav', function(e,until,cb) {
       var children = root.children();
       until = until || children.first();
       var last = children.last();
       var clear_last = function() {
         if (root.children().last() != until) {
           root.trigger('pop.columnav',[clear_last]);
         } else {
           var cb_object = {event:e,container:root,until:until};
           callback_or_default(cb,settings.on_clear)(cb_object);
         }
       };
     });
     root.children().each(function() {
       new_column(this, root);
     });
   });

 };

}(jQuery));

