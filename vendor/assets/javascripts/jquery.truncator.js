// HTML Truncator for jQuery
// by Henrik Nyh <http://henrik.nyh.se> 2008-02-28.
// Free to modify and redistribute with credit.

(function (factory) {
    if (typeof define === 'function' && define.amd)
        define(['jquery'], factory); // AMD support for RequireJS etc.
    else
        factory(jQuery);
}(function ($) {

    var trailing_whitespace = true;

    $.fn.truncate = function(options) {

        var opts = $.extend({}, $.fn.truncate.defaults, options);

        $(this).each(function() {

            var content_length = $.trim(squeeze($(this).text())).length;
            if (content_length <= opts.maxLength)
                return;  // bail early if not overlong

            var actual_max_length = opts.maxLength - opts.more.length - 3;  // 3 for " ()"
            var truncator = (opts.stripFormatting ? truncateWithoutFormatting : recursivelyTruncate);
            var truncated_node = truncator(this, actual_max_length);

            var full_node = $(this).hide();

            truncated_node.insertAfter(full_node);

            findNodeForMore(truncated_node).append(opts.moreSeparator+'<a href="#showMoreContent">'+opts.more+'</a>');
            if (opts.less)
                findNodeForLess(full_node).append(opts.lessSeparator+'<a href="#showLessContent">'+opts.less+'</a>');

            var nodes = truncated_node.add(full_node);
            var controlLinkSelector = 'a[href^="#show"][href$="Content"]:last';
            if (opts.linkClass && opts.linkClass.length > 0)
                nodes.find(controlLinkSelector).addClass(opts.linkClass);

            nodes.find(controlLinkSelector).click(function() {
                nodes.toggle(); return false;
            });
        });
    };

    // Note that the " (…more)" bit counts towards the max length – so a max
    // length of 10 would truncate "1234567890" to "12 (…more)".
    $.fn.truncate.defaults = {
        maxLength: 100,
        more: '…more',
        less: 'less', // Use null or false to omit
        moreSeparator: '…&nbsp;', // Content between the truncated text and "more" link
        lessSeparator: '&nbsp;',  // Content between the full text the the "less" link
        stripFormatting: false
    };

    function truncateWithoutFormatting(node, max_length) {
        return $(node).clone().empty().text(squeeze($(node).text()).slice(0, max_length));
    }

    function recursivelyTruncate(node, max_length) {
        return ((node.nodeType == 3) ? truncateText : truncateNode)(node, max_length);
    }

    function truncateNode(node, max_length) {
        var node = $(node);
        var new_node = node.clone().empty();
        var truncatedChild;
        node.contents().each(function() {
            var remaining_length = max_length - new_node.text().length;
            if (remaining_length === 0) return;  // breaks the loop
            truncatedChild = recursivelyTruncate(this, remaining_length);
            if (truncatedChild) new_node.append(truncatedChild);
        });
        return new_node;
    }

    function truncateText(node, max_length) {
        var text = squeeze(node.data);
        if (trailing_whitespace)  // remove initial whitespace if last text
            text = text.replace(/^ /, '');  // node had trailing whitespace.
        trailing_whitespace = !!text.match(/ $/);
        text = text.slice(0, max_length);
        // Ensure HTML entities are encoded
        // http://debuggable.com/posts/encode-html-entities-with-jquery:480f4dd6-13cc-4ce9-8071-4710cbdd56cb
        return $('<div/>').text(text).html();
    }

    // Collapses a sequence of whitespace into a single space.
    function squeeze(string) {
        return string.replace(/\s+/g, ' ');
    }

    function findNodeForMore(node) {
        var isBlock = function(i) {
            var display = $(this).css('display');
            return (display && display!='inline');
        };
        var child = node.children(":last").filter(isBlock);
        return child.length > 0 ? findNodeForMore(child) : node;
    }

    function findNodeForLess(node) {
        return $(node.children(":last").filter('p')[0] || node);
    };

}));