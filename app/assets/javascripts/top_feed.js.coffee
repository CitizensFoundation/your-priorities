$ ->
  $('a.load-more-posts').on 'inview', (e, visible) ->
    return unless visible

    $.getScript $(this).attr('href')