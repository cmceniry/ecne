class AccountController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  # If you want "remember me" functionality, add this before_filter to Application Controller
  # before_filter :login_from_cookie
  before_filter :login_required, :except => [ :login, :logout ]
  before_filter :require_pwzar, :except => [ :login, :logout, :profile, :add_my_tag, :delete_my_tag ]

  filter_parameter_logging :password

  # say something nice, you goof!  something sweet.
  def index
    redirect_to(:action => 'login') unless logged_in? || User.count > 0
    redirect_to(:controller => 'pw', :action => 'index')
  end

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(:controller => '/pw', :action => 'index')
      flash[:notice] = "Logged in successfully"
    else
      flash[:notice] = "Your login attempt failed."
    end
  end

  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => '/account', :action => 'login')
  end

  def profile
    @user = current_user
    if request.post?
      if @user.update_attributes({:password => params[:user][:password],
                                  :password_confirmation => params[:user][:password_confirmation]})
        @user.save
      end
    end
  end

  def add_my_tag
    t = Tag::get(params[:tag][:name])
    current_user.tags << t unless current_user.tags.include?(t)
    current_user.reload
    redirect_to :action => 'profile'
  end

  def delete_my_tag
    @mt = MyTag.find(params[:id])
    @mt.destroy
    current_user.reload
    redirect_to :action => 'profile'
  end

  def admin
  end

  def new
    @user = User.new(params[:user])
    return unless request.post?
    @user.save!
    redirect_to :action => 'edit', :id => @user.id
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @user = User.find(params[:id])
    if request.post?
      if @user.update_attributes(params[:user].reject {|k,v| v.empty?})
        @user.save
      end
    end
  end

  private

  def require_pwzar
    unless Ecne::groups[current_user.login].include?('pwzar')
      render :text => 'You are not allowed here'
      false
    else
      true
    end
  end

end
