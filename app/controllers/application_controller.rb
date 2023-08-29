class ApplicationController < ActionController::Base
  include Pundit

  before_action :configure_permitted_parameters, if: :devise_controller?



  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery :with => :exception

  # Valid request formats
  respond_to :html, :json

  # Devise filters
  before_action  :authenticate_user!, :user_signed_in?, :current_user, :user_session

  before_action :configure_permitted_parameters, :if => :devise_controller?

  rescue_from Pundit::NotAuthorizedError, :with => :user_not_authorized

  #before_action  :is_approved


  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :institution_id, :password, :password_confirmation])
  end

  def is_approved
    unless current_user.approved
      redirect_to not_approved_users_path
    end
  end

  def user_is_super_admin
    unless current_user.super_admin
      redirect_to diagrams_path, :status => :unauthorized
    end
  end

  protected
  # def configure_permitted_parameters
  #   devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me, :institution_id, :name, :title, :department) }
  #   devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me, :institution_id, :name, :title, :department) }
  #   devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password, :institution_id, :name, :title, :department) }
  # end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:title, :department, :name, :institution_id])
  end

  private

  def user_not_authorized
    flash[:alert] = "Access denied."
    redirect_to "/"
  end

end
