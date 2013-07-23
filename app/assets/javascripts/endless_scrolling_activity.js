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
              url: '/feed/top_feed',
              data: {
                  last: jQuery("#endless_scroll_ul").attr('last')
              },
              dataType: 'script'
            });
        }
    });
});