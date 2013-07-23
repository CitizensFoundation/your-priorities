/*jslint white: true, browser: true, onevar: true, undef: true, nomen: true, eqeqeq: true, plusplus: true, bitwise: true, regexp: true, strict: true, newcap: true, immed: true */
/*global jQuery */
"use strict";

(function ($) {
    // the public function to init the plugin
    $.fn.dd = function (options) {
        return this.each(function () {
            var elem, selected, main_div, option_list, input, attrs, attr, button, settings;
            
            settings = $.extend({}, $.fn.dd.defaults, options);
            
            // convenience
            elem = $(this);
            
            // get the currently selected value of the select
            selected = $(this).val();
            
            main_div = $('<div><span class="dd_current"></span></div>');
            input = $('<input type="hidden"/>');
            
            // Build attrs object
            // if they're not defined set them equal to ''
            // so we can easily check length when we loop
            // this solves the edge case of someone defining 
            // an attribute or id that resolves to 'false' in js
            // class is a reserved word, so jslint complained 
            // unless I quote it.
            attrs = {
                'class': elem.attr('class') || '',
                rel: elem.attr('rel') || '',
                id: elem.attr('id') || '',
                name: elem.attr('name') || '',
                title: elem.attr('title') || '',
                value: elem.val() || ''
            };
            
            // loop through options in select and create divs with rel for value
            // if there's not value attribute in option use the option contents
            // just like browsers normally do
            option_list = $('<ul></ul>');
            
            // loop through all the options and create
            // <li>'s for them using 'rel' attribute as
            // the value.
            elem.children('option').each(function () {
                var li;
                
                // new list item
                li = $('<li></li>');
                
                // if the option had a class grab it
                if ($(this).attr('class')) {
                    li.attr('class', $(this).attr('class'));
                }
                
                // if we have an option add the plugin's class
                if (settings.option_class.length) {
                    li.addClass(settings.option_class);
                }
                
                // if it has a set value grab it
                // if not grab the html() value
                if ($(this).attr('value') === '' || $(this).attr('value').length) {
                    li.attr('rel', $(this).attr('value'));
                }
                else {
                    li.attr('rel', $(this).html());
                }
                
                // set the innerhtml
                li.html($(this).html());
                
                // build the list
                option_list.append(li);
            });
            
            // add it to the main div
            main_div.append(option_list);
                    
            // remove it from the dom
            elem.replaceWith(main_div);
            
            // now we want to write all the attributes of the original 
            // select box to the new container div.
            // except for the name which gets written to our new hidden
            // text input element.
            for (attr in attrs) {
                // make sure we don't loop through prototype properties
                // make sure the attr isn't blank
                if (attrs.hasOwnProperty(attr)) {
                    if (attr === 'name') {
                        input.attr('name', attrs.name);
                    }
                    else if (attr === 'value') {
                        input.val(attrs.value);
                    }
                    else if (attrs[attr].length > 0) {
                        main_div.attr(attr, attrs[attr]);
                    }
                }
            }
            
            // put the input into the div
            main_div.append(input);
            
            // create the drop-down button
            if (settings.seperate_arrow_div) {
                button = $('<div class="dd_button"></div>');
                main_div.prepend(button);
            }
            
            // add our itentifing class
            if (settings.main_class) {
                main_div.addClass(settings.main_class);
            }
            
            // we set the overflow property to hidden,
            // this is what controls the visibility of
            // the options
            main_div.css('overflow', 'hidden');
                        
            // handle the option clicks
            main_div.delegate('li', 'click', function () {
                input.val($(this).attr('rel'));
                
                main_div.children('.dd_current').html($(this).html());
                
                if ($.isFunction(settings.change_callback)) {
                    settings.change_callback.apply(this);
                }
            });
            
            // if we had a value of the selectbox, set it on our new div
            if (selected) {
                main_div.dd_set_value(selected);
            }
            else {
            	// set first
            	main_div.dd_set_value(option_list.children().first().attr('rel'));
            }
                        
            // listen for click events in the document
            // and either hide or show depending on target
            $(document).click(function (e) {
                // if event target partents don't include the id of the
                // of this main div, then we need to hide it 
                if ($(e.target).parents('#' + main_div.attr('id')).length || $(e.target).attr('id') === main_div.attr('id')) {
                    if (main_div.css('overflow') === 'hidden') {
                        main_div.css({'overflow': 'visible', 'z-index': 9999999999});
                    }
                    else {
                        main_div.css({'overflow': 'hidden', 'z-index': ''});
                    }
                }
                else {
                    main_div.css({'overflow': 'hidden', 'z-index': ''});
                }
    
            });
            
            return main_div;
        });
    };
    
    $.fn.dd_set_value = function (val, callback) {
        return this.each(function () {
            var option;
            
            option = $(this).children('ul').children('li[rel=' + val + ']');
            
            if (option.length) {
                $(this).children('input').val(option.attr('rel'));
                $(this).children('span.dd_current').html(option.html());
            }
            
            // check to make sure callback is a function and execute it.
            if ($.isFunction(callback)) {
                callback.apply(option);
            }
            
            return this;
        });
    };
    
    $.fn.dd_new_data = function (data) {
        // expects an array of name value pairs or a simple
        // one dimensional array of just values
        return this.each(function () {
            var i, multi, list;
            
            multi = data[0] instanceof Array;
            
            // get the ul for convenience
            list = $(this).children('ul');
            
            // empty it
            list.empty();
            
            if (multi) {
                for (i = 0; i < data.length; i += 1) {
                    list.append($('<li rel="' + data[i][0] + '">' + data[i][1] + '</li>'));
                }
            }
            else {
                for (i = 0; i < data.length; i += 1) {
                    list.append($('<li rel="' + data[i] + '">' + data[i] + '</li>'));
                }
            }
            
            return this;
        });
    };
    
    $.fn.dd.defaults = {
        main_class: 'dd',
        seperate_arrow_div: true,
        option_class: 'option',
        button_class: 'dd_button',
        autocomplete: true,
        change_callback: function () {}
    };
}(jQuery));