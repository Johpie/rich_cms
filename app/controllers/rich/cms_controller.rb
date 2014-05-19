module Rich
  class CmsController < ::ApplicationController
    before_filter :require_login, :except => [:display, :position]

    def display
      session[:rich_cms_display] = params[:display]
      request.xhr? ? render(:nothing => true) : redirect_to("/")
    end

    def position
      session[:rich_cms_position] = params[:position]
      render :nothing => true
    end

    def update
      css_class, identifier, value = *params[:content_item].values_at(:__css_class__, :store_key, :store_value)

      content       = Cms::Content.fetch css_class, identifier
      content.value = value

      render :json => content.save_and_return(:always).to_json(params[:content_item])
    end

  private

    def require_login
      if Rich::Cms::Auth.login_required?
        if request.xhr?
          render :update do |page|
            page.reload
          end
        else
          redirect_to request.referrer
        end
        return false
      end
      true
    end

  end
end