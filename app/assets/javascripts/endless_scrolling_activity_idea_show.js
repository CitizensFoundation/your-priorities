jQuery(document).ready(function() {
    $(document).endlessScroll({
      fireOnce: true,
      bottomPixels: 200,
      fireDelay: 300,
        ceaseFire: function(){
          return jQuery('#infinite-scroll').length ? false : true;
        },
        callback: function(){
          jQuery.ajax({
              url: '/ideas/show_feed/'+jQuery("#endless_scroll_ul_idea_show").attr('idea_id'),
              data: {
                  last: jQuery("#endless_scroll_ul_idea_show").attr('last')
              },
              dataType: 'script'
            });
        }
    });
});