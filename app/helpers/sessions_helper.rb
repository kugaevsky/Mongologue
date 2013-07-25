module SessionsHelper

  def sign_in(user)
    user.remember_me!
    cookies[:remember_token] = { :value   => user.remember_token,
                                 :expires => 20.years.from_now.utc }
    self.current_user = user
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user ||= user_from_remember_token
  end

  def user_from_remember_token
    remember_token = cookies[:remember_token]
    user=User.where(:remember_token => remember_token).first unless remember_token.nil?
    if user.nil?
      cookies.delete(:remember_token)
    end
    user
  end

  def signed_in?
    !current_user.nil?
  end

  def sign_out
    cookies.delete(:remember_token)
    self.current_user = nil
  end

  def current_user?(user)
    user == current_user
  end

  def current_user_name
    if current_user.nil?
      "Anonymous"
    else
      identity_or_name(current_user)
    end
  end

  def authenticate
    deny_access unless signed_in?
  end

  def deny_access
    redirect_to root_path
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end

  def clear_return_to
    session[:return_to] = nil
  end

   def identity_or_name(user)
    if user[:name].nil?
      user[:identity]
    elsif user['name']['full_name'].nil?
      "#{user['name']['first_name']} #{user['name']['last_name']}"
    else
      user['name']['full_name']
    end
  end

  def admin_user
    redirect_to(root_path) unless current_user.admin?
  end

  def authorized_admin?
    if signed_in?
      if current_user.admin?
        return true
      end
    end
    return false
  end
end
