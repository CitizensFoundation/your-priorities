$:.unshift "#{File.dirname(__FILE__)}/lib"
require File.dirname(__FILE__) + '/../../lib/facebox_render/facebox_render'
require File.dirname(__FILE__) + '/../../lib/facebox_render/facebox_render_helper'

ActionController::Base.helper FaceboxRenderHelper