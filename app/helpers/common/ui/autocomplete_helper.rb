module Common::Ui::AutocompleteHelper

  #
  # creates the javascript for autocomplete on text field with field_id
  #
  # required:
  #   field_id  -- the dom id of the text_field tag
  #
  # options:
  #  :keypress  -- js function when key is pressed.
  #  :onselect  -- what js function to run when an item is selected
  #  :message   -- the message to display, if any, before a user starts to type.
  #  :container -- the dom id of an element that will be the container for the popup. optional
  #

#  def autocomplete_entity_tag(field_id, options={})
#    options[:url] ||= '/entities'
#    options[:onselect] ||= 'null'
#    auto_complete_js = %Q[
#      new Autocomplete('#{field_id}', {
#        serviceUrl:'#{options[:url]}',
#        minChars:2,
#        maxHeight:400,
#        width:300,
#        onSelect: #{options[:onselect]},
#        message: '#{escape_javascript(options[:message])}',
#        container: '#{options[:container]}',
#        preloadedOnTop: true,
#        rowRenderer: #{render_entity_row_function},
#        selectValue: #{extract_value_from_entity_row_function}
#      }, #{autocomplete_id_number});
#    ]
#    javascript_tag(auto_complete_js)
#  end

  # this searches on friends and peers. if needed, we could modify
  # this to allow the option to search all users.
  def autocomplete_users_field_tag(field_id, options = {})
    options.merge! :view => 'recipients'
    autocomplete_entity_field_tag(field_id, options) #should this always be recipients?
  end

  # just for groups
  def autocomplete_groups_field_tag(field_id, options = {})
    options.merge! :view => 'groups'
    autocomplete_entity_field_tag(field_id, options)
  end

  # for groups and users
  def autocomplete_entity_field_tag(field_id, options={})
    # setup options
    options[:view] ||= 'all'
    options[:onkeypress] ||= eat_enter
    if options[:onselect] || options[:message] || options[:container]
      options[:onselect] ||= 'null'
      option_string = ", {onSelect: #{options[:onselect]}, message: '#{escape_javascript(options[:message])}', container: '#{options[:container]}'}"
    else
      option_string = ""
    end

    # create tag
    text_field_tag(field_id, '', :style => options[:style], :onkeypress => options[:onkeypress]) +
    javascript_tag("cgAutocompleteEntities('%s', '%s' %s)" % [
      field_id,
      entities_path(:view => options[:view], :format => 'json'),
      option_string
    ])
  end

  private

  def autocomplete_id_number
    rand(100000000)
  end

  # called in order to render a popup row. it is a little too complicated.
  #
  # basically, we want to just highlight the text but not the html tags in the
  # popup row.
  #
  def render_entity_row_function
    %Q[function(value, re, data) {return '<p class=\"name_icon xsmall\" style=\"background-image: url(/avatars/'+data+'/xsmall.jpg)\">' + value.replace(/^<em>(.*)<\\/em>(<br\\/>(.*))?$/gi, function(m, m1, m2, m3){return '<em>' + Autocomplete.highlight(m1,re) + '</em>' + (m3 ? '<br/>' + Autocomplete.highlight(m3, re) : '')}) + '</p>';}]
  end

  # called to convert the row data into a value
  def extract_value_from_entity_row_function
    %Q[function(value){return value.replace(/<em>(.*)<\\/em>.*/g,'$1');}]
  end

end
