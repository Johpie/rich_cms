if Rails::VERSION::MAJOR >= 3

  Rails.application.routes.draw do
    scope :module => "rich" do
      match "/cms/"     => "cms#display" , :as => "rich_cms"     , :display => true, :via => [:get, :post]
      match "/cms/hide" => "cms#display" , :as => "rich_cms_hide", :display => false, :via => [:get, :post]
      %w(login logout).each do |action|
        match "/cms/#{action}" => "cms_sessions##{action}", :as => "rich_cms_#{action}", :via => [:get, :post]
      end
      %w(position update).each do |action|
        match "/cms/#{action}" => "cms##{action}", :as => "rich_cms_#{action}", :via => [:get, :post]
      end
    end
  end

else

  # TODO: add routes the right way as this is evil
  class << ActionController::Routing::Routes;self;end.class_eval do
    define_method :clear!, lambda {}
  end
  # END

  ActionController::Routing::Routes.draw do |map|
    map.namespace :rich, :path_prefix => "" do |rich|
      rich.cms      "cms"     , :controller => "cms", :action => "display", :display => true, :via => [:get, :post]
      rich.cms_hide "cms/hide", :controller => "cms", :action => "display", :display => false, :via => [:get, :post]
      %w(login logout).each do |action|
        rich.send "cms_#{action}", "cms/#{action}", :controller => "cms_sessions", :action => action, :via => [:get, :post]
      end
      %w(position update).each do |action|
        rich.send "cms_#{action}", "cms/#{action}", :controller => "cms", :action => action, :via => [:get, :post]
      end
    end
  end

end