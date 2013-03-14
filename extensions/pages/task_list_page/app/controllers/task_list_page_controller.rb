class TaskListPageController < Pages::BaseController
  before_filter :fetch_task_list, :fetch_user_participation
  after_filter :update_participations,
    :only => [:create_task, :mark_task_complete, :mark_task_pending, :destroy_task, :update_task]
  stylesheet 'tasks'
  permissions 'task_list_page'

  def show
  end

  # ajax only, returns nothing
  # for this to work, there must be a <ul id='sort_list_xxx'> element
  # and it must be declared sortable like this:
  # <%= sortable_element 'sort_list_xxx', .... %>
  def sort
    sort_list_key = params.keys.grep(/^sort_list_/)
    if sort_list_key.present?
      ids = params[sort_list_key[0]]
      ids.reject!{|i|i.to_i == 0} # only allow integers
      @list.tasks.each do |task|
        i = ids.index( task.id.to_s )
        task.without_timestamps do
          task.update_attribute('position',i+1) if i
        end
      end
      if ids.length > @list.tasks.length
        new_ids = ids.reject {|t| @list.task_ids.include?(t.to_i) }
        new_ids.each {|id| Task.update(id, :position => ids.index(id)+1, :task_list_id => @list.id) }
      end
    end
    render :nothing => true
  end

  # ajax only, returns rjs
  def create_task
    return unless request.xhr?
    @task = Task.new(params[:task])
    @task.name = 'untitled' unless @task.name.present?
    @task.task_list = @list
    @task.save
    render :template => 'task_list_page/create_task'
  end

  # ajax only, returns rjs
  def mark_task_complete
    return unless request.xhr?
    @task = @list.tasks.find(params[:id])
    @task.completed = true
    @task.move_to_bottom # also saves task
    render :template => 'task_list_page/mark_task_complete'
  end

  # ajax only, returns rjs
  def mark_task_pending
    return unless request.xhr?
    @task = @list.tasks.find(params[:id])
    @task.completed = false
    @task.move_to_bottom # also saves task
    render :template => 'task_list_page/mark_task_pending'
  end

  # ajax only, returns nothing
  def destroy_task
    return unless request.xhr?
    @task = @list.tasks.find(params[:id])
    @task.remove_from_list
    @task.destroy
    render :nothing => true
  end

  # ajax only, returns rjs
  def update_task
    return unless request.xhr?
    @task = @list.tasks.find(params[:id])
    @task.update_attributes(params[:task])
    @task.name = 'untitled' unless @task.name.present?
    render :update do |page|
      page.replace_html dom_id(@task), :partial => 'inner_task_show', :locals => {:task => @task}
    end
  end

  # ajax only, returns rjs
  def edit_task
    return unless request.xhr?
    @task = @list.tasks.find(params[:id])
    render :update do |page|
      page.replace_html dom_id(@task), :partial => 'inner_task_edit', :locals => {:task => @task}
    end
  end

  protected

  def initialize(options={})
    super(options)
    @second_nav = 'tasks'
  end

  def update_participations
    users_pending = {}
    page_resolved = true

    # build a hash of the completed status for each user
    @list.tasks.each do |task|
      task.users.each do |user|
        users_pending[user] ||= (not task.completed?)
      end
      page_resolved &&= task.completed?
    end

    # make the page resolved iff all the tasks are completed
    @page.update_attribute(:resolved, page_resolved) if @page.resolved? != page_resolved

    # update each user's resolved status
    users_pending.each do |user,pending|
      user.resolved(@page, (not pending))
    end

    # current_user.updated(@page) <-- if we want the page to become unread on each update
    @page.save # instead of current_user.updated
    return true
  end

  def fetch_task_list
    return true unless @page
    unless @page.data
      @page.data = TaskList.create
      current_user.updated @page
    end
    @list = @page.data
  end

  def fetch_user_participation
    @upart = @page.participation_for_user(current_user) if @page and current_user
  end



end
