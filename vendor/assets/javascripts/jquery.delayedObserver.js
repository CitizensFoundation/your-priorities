/*
 jQuery delayed observer - 0.8
 http://code.google.com/p/jquery-utils/

 (c) Maxime Haineault <haineault@gmail.com>
 http://haineault.com
 
 MIT License (http://www.opensource.org/licenses/mit-license.php)
 
*/

(function($){
    $.extend($.fn, {
        delayedObserver: function(callback, delay, options){
            return this.each(function(){
                var el = $(this);
                var op = options || {};
                el.data('oldval', el.val())
                    .data('delay', delay || 0.5)
                    .data('condition', op.condition || function() { return ($(this).data('oldval') == $(this).val()); })
                    .data('callback', callback)
                    [(op.event||'keyup')](function(){
                        if (el.data('condition').apply(el)) { return; }
                        else {
                            if (el.data('timer')) { clearTimeout(el.data('timer')); }
                            el.data('timer', setTimeout(function(){
                                el.data('callback').apply(el);
                            }, el.data('delay') * 1000));
                            el.data('oldval', el.val());
                        }
                    });
            });
        }
    });
})(jQuery);

(function($){
  
  var options  = {};
  var activity = {};
  
  $.fn.observeForm = function(opts) {
    options  = $.extend({}, opts);
    activity = {};
    
    //console.log('Starting form observer');
    
    //var allFieldsSel   = ':input:not(:hidden)';
    var changeFieldSel = ':checkbox, :radio, select';
    var keyFieldSel    = ':text, :password, textarea';
    var btnFieldSel    = ':button, :reset, :submit, :image';
    
    return this
      .ready(serverValidationObserver)
      .submit(jsValidationObserver)
      .delegate(changeFieldSel, 'change',   fieldActivityHandler)
      .delegate(keyFieldSel,    'keypress', fieldActivityHandler)
      .delegate(btnFieldSel,    'click',    fieldActivityHandler);

  }

  $.fn.observeForm.plugins = {
    getMessageInfo: function(label) {
      var fieldId = label.attr('for');
      
      var fieldLabel = $.trim(
        $('label[for=' + fieldId + ']')
          .not('.error')
          .contents()
          .filter(function() {
              return this.nodeType == 3;
            })
          .text()
      );
        
      return {
        name: $('#' + fieldId).attr('name'),
        label: fieldLabel,
        error: label.text()
      }
    },
    
  }

  serverValidationObserver = function(e) {
    //console.log('Observing server-side validation messages');
    if (options.validation) {
      $(options.validation).each(function(){
        var message = $.fn.observeForm.plugins.getMessageInfo($(this));
        message.type = 'validation.server';
        $(this).trigger('form.validation', [message]);
      });
    }
  }
  
  jsValidationObserver = function(e) {
    //console.log('Observing client-side validation messages');
    var form = $(this);

    setTimeout(function() {
      if (options.validation) {
        $(options.validation).each(function(){
          var message = $.fn.observeForm.plugins.getMessageInfo($(this));
          message.type = 'validation.javascript';
          form.trigger('form.validation', [message]);
        });
      }
    }, 500);
  }
  
  fieldActivityHandler = function(e) {
    //console.log('Observing field activity');
    var field = $(this);
    var name  = field.attr('name');
    
    if (name && !activity[name]) {
      var message = {
        type: 'activity.field',
        name: field.attr('name')
      }
      field.trigger('form.activity', [message]);
      activity[name] = 1;
    }
  }
  
  
})(jQuery);
