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

   var new_column = function(el, root) {
     var $el = $(el).css({
       display: 'inline-block',
       verticalAlign: 'top',
       whiteSpace: 'normal',
       listStyle: 'none'
     });
     $('.'+settings.link_class, $el)
     .on('click.columnav', function(e,cb) {
       if (!root.busy) {
         root.busy = true;
         $('.'+settings.link_class, $el).removeClass(settings.selected_link_class);
         var $this = $(this).addClass(settings.selected_link_class);
         var removable = $this.parents('.'+settings.column_class).nextAll();
         if (removable.length === 0) {
           root.trigger('getandpush.columnav',[$this.attr('href'),cb]);
         } else {
           root.trigger('pop.columnav',[removable,function(cb_info) {
             root.trigger('getandpush.columnav',[$this.attr('href'),cb]);
           }]);
         }
       }
       e.preventDefault();
     });
   };

   return this.each(function(){
     var root = $(this).css({
       overflow: 'scroll',
       whiteSpace: 'nowrap'
     });
     root.busy = false;
     root.on('push.columnav', function(e,data,cb) {
       var $data = $("<li class='"+settings.column_class+"'>"+data+"</li>");
       root.append($data);
       new_column($data, root);
       var cb_object = {event:e,column:$data,container:root,settings:settings};
       root.animate({scrollLeft: root.width()},function(){
         root.busy = false;
         settings.on_push(cb_object);
         if (typeof cb == 'function') cb(cb_object);
       });
     });
     root.on('getandpush.columnav', function(e,url,cb) {
       $.get(url, function(data) {
         root.trigger('push.columnav',[settings.process_data(data),function(cb_object) {
           cb_object.column.data('href',url);
           if (typeof cb == 'function') cb(cb_object);
         }]);
       });
     });
     root.on('pop.columnav', function(e,removable,cb) {
       removable = removable || root.children().last();
       removable.css({visibility:'hidden'})
       .animate({width:0},function(){
         // Trick to make sure it runs only once
         // not for each column removed
         if (removable.filter(':animated').length === 0) {
           removable.remove();
           var cb_object = {event:e,container:root,settings:settings}
           settings.on_pop(cb_object);
           if (typeof cb == 'function') cb(cb_object);
         }
       });
     });
     root.children().each(function() {
       new_column(this, root);
     });
   });

 };

}(jQuery));

