class Users::InvitationsController < Devise::InvitationsController
  # POST /resource/invitation
  def create
    self.resource = resource_class.invite!(resource_params, current_user)

    Rails.logger.debug("CREATE INVITATION: #{self.resource.inspect}")
    if resource.errors.empty?
      set_flash_message :notice, :send_instructions, :email => self.resource.email
      respond_with resource, :location => after_invite_path_for(resource)
    else
      respond_with_navigational(resource) { render :new }
    end
  end

  def after_invite_path_for(resource)
    "/subscription_accounts/users"
  end
end