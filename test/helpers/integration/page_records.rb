module PageRecords

  def own_page(type = nil, options = {})
    options, type = type, nil  if type.is_a? Hash
    options.merge! created_by: user
    page = new_page(type, options)
    if page.new_record?
      page.save
      # ensure after_commit callbacks are triggered so sphinx indexes the page.
      page.page_terms.committed!
    end
    page
  end

  def with_page(types)
    assert_for_all types do |type|
      yield new_page(type)
    end
  end

  def new_page(type=nil, options = {})
    options, type = type, nil  if type.is_a? Hash
    page_options = options.slice :title, :summary, :created_by, :owner, :flow
    page_options.merge! created_at: Time.now, updated_at: Time.now
    if type
      @page = records[type] ||= FactoryGirl.build(type, page_options)
    else
      @page ||= FactoryGirl.build(:discussion_page, page_options)
    end
  end

  def prepare_page(type, options = {})
    type_name = I18n.t "#{type}_display"
    # create page is on a hidden dropdown
    # click_on :create_page.t
    visit '/pages/create/me'
    click_on type_name
    new_page(type, options)
    fill_in_new_page_form(type, options)
  end

  def create_page(type, options = {})
    prepare_page(type, options)
    click_on :create.t
  end

  def fill_in_new_page_form(type, options)
    title = options[:title] || "#{type} - #{new_page.title}"
    file = options[:file] || fixture_file('bee.jpg')
    try_to_fill_in :title.t,      with: title
    try_to_fill_in :summary.t,    with: new_page.summary
    click_on 'Additional Access'
    try_to_attach_file :asset_uploaded_data, file
    # workaround for having the right page title in the test record
    new_page.title = file.basename(file.extname) if type == :asset_page
  end
end
