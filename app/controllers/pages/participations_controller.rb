#
# Routes:
#
#  create:  page_participations_path  /pages/:page_id/participations
#  update:  page_participation_path   /pages/:page_id/participations/:id
#

class Pages::ParticipationsController < Pages::SidebarsController

  guard :may_show_page?, actions: [:update, :create]
  helper 'pages/participation', 'pages/share'

  before_filter :fetch_data

  # this is used for ajax pagination
  def index
  end

  def update
    if params[:watch]
      watch
    elsif params[:star]
      star
    elsif params[:access]
      raise_denied unless may_admin_page?
      access
    end
  end

  def create
    update
  end

  protected

  def watch
    @upart = @page.add(current_user, watch: params[:watch])
    @upart.save!
  end

  def star
    @upart = @page.add(current_user, star: params[:star])
    @upart.save!
  end

  def access
    if params[:access] == 'remove'
      destroy
    else
      @page.add(@participation.entity, access: params[:access]).save!
    end
  end

  ## technically, we should probably not destroy the participations
  ## however, since currently the existance of a participation means
  ## view access, then we need to destory them to remove access.
  def destroy
    if may_remove_participation?(@participation)
      if @participation.is_a? UserParticipation
        @page.remove(@participation.user)
      else
        @page.remove(@participation.group)
      end
    else
      raise ErrorMessage.new(:remove_access_error.t)
    end
  end

  protected

  def fetch_data
    if params[:group].blank? || params[:group] == 'false'
      @participation = UserParticipation.find(params[:id]) if params[:id]
    else
      @participation = GroupParticipation.find(params[:id]) if params[:id]
    end
  end

end

