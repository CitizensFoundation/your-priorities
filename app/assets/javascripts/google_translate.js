/**
 * @author Robert Bjarnason
 */

function google_translate_all_content(locale) {
  $('.to_translate').translate(locale,{ walk: false, toggle: false});
};
