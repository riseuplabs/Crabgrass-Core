class Wikis::VersionsController < Wikis::BaseController

  before_filter :fetch_version, :only => [:show, :destroy, :revert]
  before_filter :login_required

  permissions 'wikis/versions'
  layout proc{ |c| c.request.xhr? ? false : 'sidecolumn' }
  javascript :wiki

  def show
  end

  def index
    @versions = @wiki.versions.most_recent.
      paginate(pagination_params(:per_page => 10))
    @version = @versions.first
  end

  def destroy
    @version.destroy
    if @version.destroyed?
      success :wiki_version_destroy_success.t
    else # last version
      warning :wiki_version_destroy_failed.t
    end
    redirect_to wiki_path(@wiki)
  end

  def revert
    @wiki.revert_to(@version, current_user)
    redirect_to wiki_path(@wiki)
  end

  protected

  def fetch_version
    @version = @wiki.find_version(params[:id])
  rescue Wiki::VersionNotFoundException => ex
    flash.now[:error] =  ex.message
    return false
  end

end


