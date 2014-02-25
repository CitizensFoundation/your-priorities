class PasswordsController < Devise::PasswordsController

=begin
  def new
    super
    add_devise_validation_errors_to_flash!
    @page_title = tr("Reset your {instance_name} password", "controller/passwords", :instance_name => current_instance.name)
  end
=end
end
