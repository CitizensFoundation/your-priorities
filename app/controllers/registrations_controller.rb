class RegistrationsController < Devise::RegistrationsController

  before_filter :add_devise_validation_errors_to_flash!, only: [:create, :edit]

  def after_update_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || '/'
  end

  def after_sign_up_path_for(resource_or_scope)
    if session["omniauth_data"]
      if not current_user.facebook_uid and session["omniauth_data"][:facebook_id]
        current_user.facebook_uid = session["omniauth_data"][:facebook_id]
        current_user.save(validate: false)
      end
      current_user.remember_me!
    end
    session.delete("omniauth_data")

    session[:goal] = 'signup'
    if session[:query]
      session[:query] = nil
      return "/?q=" + session[:query]
    else
      return stored_location_for(resource_or_scope) || '/'
    end
  end

  def create
    build_resource(sign_up_params)

    #if !Rails.env.test? && !verify_recaptcha
    #  flash.now[:error] = tr("There was an error with the recaptcha code below. Please re-enter the code.", 'controller/registrations')
    #  flash.delete :recaptcha_error
    #  clean_up_passwords(resource)
    #  respond_with resource
    #  return
    #end

    #resource.request = request
    #resource.referral = @referral
    #resource.sub_instance_referral = current_sub_instance
    resource.sub_instance_id = SubInstance.current.id
    if resource.save
      yield resource if block_given?
      resource.activate!
      if resource.active_for_authentication?
        if is_navigational_format?
          flash[:notice] = tr("Welcome to {instance_name}", "controller/registrations", instance_name: current_instance.name)
        end
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      respond_with resource
    end
  end
end

