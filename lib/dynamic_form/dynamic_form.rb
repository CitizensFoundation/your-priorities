require File.dirname(__FILE__) + '/../../lib/dynamic_form/action_view/helpers/dynamic_form'

class ActionView::Base
  include DynamicForm
end
