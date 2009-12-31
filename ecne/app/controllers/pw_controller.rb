class PwController < ApplicationController
  include AuthenticatedSystem
  before_filter :login_required, :authorization_required
  after_filter  :pwlog

  filter_parameter_logging :value
  
  def index
  end
  
  def noop
    render :update do |page|
      page.replace_html "main-data", :partial => 'nothing'
    end
  end

  def search
    @search_text = params[:search_text] || ""
    @search_inactive = params[:search_inactive].nil? ? "0" : params[:search_inactive]
    @search_active = params[:search_inactive] == "1" ? "0" : "1"
    @password_pages, @passwords = paginate :passwords,
      :per_page => 40,
      :conditions => [ "passwords.id IN (?)", Password.search(@search_text, @search_active) ],
      :order => "contextname ASC, accountname ASC",
      :include => :category
    if @passwords.empty?
      render :update do |page|
        @filler = "Nothing Found"
        page.replace_html 'navigation', :partial => 'filler'
      end
    else
      render :update do |page|
        page.replace_html "navigation", :partial => 'list'
      end
    end
  end

  def show
    @password = Password.find(params[:id])
    @writer   = @password.can?(['w'], current_user.login)
    render :update do |page|
      page.delay(Ecne::displaytimeout) do
        page.replace_html "password-value-#{@password.id}", :partial => 'nothing'
      end
      page.replace_html 'main-data', :partial => 'show'
    end
  end

  def showall
    @password = Password.find(params[:id], :include => :password_entries)
    @writer   = @password.can?(['w'], current_user.login)
    render :update do |page|
      page.delay(Ecne::displaytimeout) do
        page.replace_html "all-password-#{@password.id}", :partial => 'nothing'
      end
      page.replace_html 'main-data', :partial => 'showall'
    end
  end

  def new
    @password = Password.new(:active => 1)
    @writer   = true
    render :update do |page|
      page.replace_html 'main-data', :partial => 'new'
    end
  end

  def create
    @password = Password.new(:accountname => params[:password][:accountname],
                             :contextname => params[:password][:contextname],
                             :category_id => params[:password][:category_id],
                             :active      => params[:password][:active])
    @password.modifier = current_user.login
    unless @password.save
      render :update do |page|
        page.replace_html 'main-data', :partial => 'new'
      end
      return
    end
    @password.newvalue = params[:password][:newvalue]
    @password.tags << Tag.get("w:u:#{current_user.login}")
    @writer   = @password.can?(['w'], current_user.login)
    render :update do |page|
      page.delay(Ecne::displaytimeout) do
        page.replace_html "password-value-#{@password.id}", :partial => 'nothing'
      end
      page.replace_html 'main-data', :partial => 'show'
    end
  end

  def change_password
    @password = Password.find(params[:id])
    @writer   = @password.can?(['w'], current_user.login)
    render :update do |page|
      page.replace_html 'main-data', :partial => 'change_password'
    end
  end
  
  def edit
    @password = Password.find(params[:id])
    @writer   = @password.can?(['w'], current_user.login)
    render :update do |page|
      page.replace_html 'main-data', :partial => 'edit'
    end
  end

  def update
    @password = Password.find(params[:id])
    @writer   = @password.can?(['w'], current_user.login)
    @password.modifier = current_user.login
    if @password.update_attributes(params[:password].reject {|k,v| v.empty?})
      render :update do |page|
        page.replace_html 'main-data', :partial => 'show'
      end
    else
      render :update do |page|
        page.replace_html 'main-data', :partial => 'edit'
      end
    end
  end

  def add_tag
    @tag = nil
    if params[:tagid]
      @tag = Tag.find(params[:tagid])
    else
      @tag = Tag.get(params[:tag][:name])
    end
    @password = Password.find(params[:id])
    @password.modifier = current_user.login
    @writer   = @password.can?(['w'], current_user.login)
    if not @password.tags.include?(@tag)
      @password.tags << @tag
      @password.save
      @password.reload
    end
    render :update do |page|
      page.replace_html 'password-tags', :partial => 'tags'
      page.form.reset 'tag-form'
    end
  end

  def delete_tagging
    @tagging = Tagging.find(params[:id])
    @password = Password.find(@tagging.taggable_id)
    @password.modifier = current_user.login
    @writer   = @password.can?(['w'], current_user.login)
    if @tagging.destroy
      @password.reload
      render :update do |page|
        page.replace_html 'password-tags', :partial => 'tags'
      end
    end
  end
  
  def generate
    @filler = Ecne::apg(params[:gen])
    render :update do |page|
      page.replace_html 'password_newvalue', :partial => 'filler'
    end
  end

  private

  def authorization_failed
    @auth_failed = true
    render :update do |page|
      page.replace_html 'main-data', :partial => 'notallowed'
    end
    false
  end
  
  def authorization_required
    @auth_failed = false
    perms = nil
    password_id = nil
    case action_name
    when "index", "noop", "search", "create", "new", "generate"
      return false if current_user.nil?
      return true
    when "show", "showall"
      password_id = params[:id]
      perms       = ["r", "w"]
    when "edit", "change_password", "update", "add_tag"
      password_id = params[:id]
      perms       = ["w"]
    when "delete_tagging"
      password_id = Tagging.find(params[:id]).taggable_id
      perms       = ["w"]
    else
      return authorization_failed
    end
    @authorization_target = Password.find(password_id)
    @authorization_target.can?(perms, current_user.login) ? true : authorization_failed
  end
  
  def target_to_s
    @authorization_target.nil? ? "unknown" : %{id #{@authorization_target.id} name "#{@authorization_target.name}"}
  end
  
  def pwlog
    if current_user.nil?
      Syslog.log(Syslog::LOG_WARNING, "%s LOGIN (from %s)", request.env['REMOTE_ADDR'], action_name)
      return true
    end
    actionmsg = ""
    case action_name
    when "index", "noop", "new", "edit", "change_password", "generate"
      return
    when "create"
      actionmsg << "create #{target_to_s}"
    when "search"
      actionmsg << %{search "#{params[:search_text]}"}
    when "show", "showall"
      actionmsg << "view #{target_to_s}"
    when "update", "add_tag", "delete_tagging"
      actionmsg << "edit #{target_to_s}"
    else
      actionmsg << "do something unexpected on #{target_to_s}"
    end
    Syslog.log(Syslog::LOG_WARNING,
               "%s(%s) %s%s",
               current_user.login,
               request.env['REMOTE_ADDR'],
               (@auth_failed ? "DENIED " : ""),
               actionmsg)               
    
  end
    
end
