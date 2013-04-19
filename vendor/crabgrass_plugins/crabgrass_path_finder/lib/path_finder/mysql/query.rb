# = PathFinder::Mysql:Query
#
# Concrete subclass of PathFinder::Query
#
# == Usage:
#
# This class generates the SQL and makes the call to find_by_sql.
# It is called from find_by_path in PathFinder::FindByPath. Look there
# for an example how to use it.
#
# == Resolving Permissions
#
# It uses a fulltext index on page_terms in order to resolve permissions for pages.
# This bypasses potentially really hairy four-way joins on user_participations
# and group_participations tables.
# (not to mention a potential 5th,6th,7th joins for tags, ugh!)
#
# An example query:
#
#  SELECT * FROM pages
#  JOIN page_terms ON pages.id = page_terms.page_id
#  WHERE
#    MATCH(page_terms.access_ids)
#    AGAINST('+(0001 0011 0081 0082) +0081' IN BOOLEAN MODE)
#
# * this is an inner join, because *every* page should
#   have a corresponding page_term.
# * page_term.access_ids is a text column with a fulltext index.
# * the format of the values in access_ids is thus:
#   * user ids are prefixed with 1
#   * group ids are prefixed with 8
#   * every id is at least four characters in length,
#     padded with zeros if necessary.
#   * if page is public, id 0001 is present.
#
# So, suppose the current user was id 1, and they were
# members of groups 1 and 2.
#
# To find all the pages of group 1 that current_user may access:
#
#    (current_user.id OR public OR current_user.all_group_ids) AND group.id
#
# In fulltext boolean mode search on access_ids, this becomes:
#
#    +(0011 0001 0081 0082) +0081
#
# The first part of this condition is called the access_me_clause. This is where we
# resolve the question "what does current user have access to?". This clause is
# based entirely on the current_user variable.
#
# The next AND clause is called the access_target_clause. This is where we ask "who's
# pages are we searching for?". This clause is based entirely on what options
# are used (ie options_for_group() or options_for_user())
#
# There can be additional AND clauses. These are called access_filter_clauses.
# This is for additional limits that pop up in the path itself. It is based
# entirely on what is in the filter path.
#

class PathFinder::Mysql::Query < PathFinder::Query

  ##
  ## OVERRIDES
  ##

  def initialize(path, options, klass)
    super

    ## page_terms access clauses
    ## (within each clause, the values are OR'ed, but the clauses are AND'ed
    ##  together in the query).
    if options[:group_ids] or options[:user_ids] or options[:public]
      @access_me_clause = "+(%s)" % Page.access_ids_for(
        :public    => options[:public],
        :group_ids => options[:group_ids],
        :user_ids  => options[:user_ids]
      ).join(' ')
    end
    if options[:secondary_group_ids] or options[:secondary_user_ids]
      @access_target_clause = "+(%s)" % Page.access_ids_for(
        :group_ids => options[:secondary_group_ids],
        :user_ids  => options[:secondary_user_ids]
      ).join(' ')
    end
    if options[:site_ids]
      @access_site_clause = "+(%s)" % Page.access_ids_for(
        :site_ids => options[:site_ids]
      ).join(' ')
    end

    @access_filter_clause = [] # to be used by path filters

    ## page stuff
    @conditions  = []
    @values      = []
    @order       = []
    @tags        = []
    @or_clauses  = []
    @and_clauses = []
    @selects     = []
    @flow        = options[:flow]
    @date_field  = 'created_at'

    # magic will_paginate paginating (count required)
    @per_page    = options[:per_page]
    @page        = options[:page]
    # limiting   (count not required)
    @limit       = nil
    @offset      = nil
    @include     = options[:include]
    @select      = options[:select]

    # klass the find/paginate/... was send to and thus of the objects we return.
    @klass = klass
    @selects <<  @klass.table_name + ".*"

    apply_filters_from_path(path)
  end

  def apply_filter(filter, args)
    query_filter = filter.query_block || filter.mysql_block
    if query_filter
      query_filter.call(self, *args)
    end
  end

  ##
  ## FINDERS
  ##

  def find
    options = options_for_find
    #puts "Page.find(:all, #{options.inspect})"
    @klass.find :all, options
  end

  def paginate
    @klass.paginate options_for_find.merge(:page => @page, :per_page => @per_page)
  end

  def count
    @order = nil
    @klass.count options_for_find
  end

  def ids
    @klass.find_ids options_for_find.merge(:select => 'pages.id')
  end

  ##
  ## utility methods called by SearchFilter classes
  ##

  def add_sql_condition(condition, value)
    @conditions << condition
    @values << value
  end

  # and a condition based on an attribute of the page
  def add_attribute_constraint(attribute, value)
    add_sql_condition("pages.#{attribute} = ?", value)
  end

  # add a condition based on the fulltext access field
  def add_access_constraint(access_hash)
    @access_filter_clause << "+(#{Page.access_ids_for(access_hash).join(' ')})"
  end

  def add_public
    add_access_constraint(:public => true)
  end

  def add_tag_constraint(tag)
    @tags << "+" + Page.searchable_tag_list([tag]).first
  end

  def add_order(order_sql)
    if @order # if set to nil, this means we must skip sorting
      if order_sql =~ /\./
        @order << order_sql
      else
        @order << "#{@klass.table_name}.#{order_sql}"
      end
    end
  end

  def add_limit(limit_count)
    @limit = limit_count
  end

  def cleanup_sort_column(column)
    case column
      when 'views' then 'views_count'
      when 'stars' then 'stars_count'
      # MISSING: when 'edits' then 'edits_count'
      when 'contributors' then 'contributors_count'
      when 'posts' then 'posts_count'
      else column
    end
    return column.gsub(/[^[:alnum:]]+/, '_')
  end

  def add_most_condition(what, num, unit)
    unit=unit.downcase.pluralize
    name= what=="edits" ? "contributors" : what
    num.gsub!(/[^\d]+/, ' ')
    if unit=="months"
      unit = "days"
      num = num.to_i * 31
    elsif unit=="years"
      unit = "days"
      num = num.to_i * 365
    end
    if unit=="days"
      @conditions << "dailies.created_at > UTC_TIMESTAMP() - INTERVAL %s DAY" % num
      @order << "SUM(dailies.#{what}) DESC"
      @select = "pages.*, SUM(dailies.#{what}) AS #{name}_count"
    elsif unit=="hours"
      @conditions << "hourlies.created_at > UTC_TIMESTAMP() - INTERVAL %s HOUR" % num
      @order << "SUM(hourlies.#{what}) DESC"
      @select = "pages.*, SUM(hourlies.#{what}) AS #{name}_count"
    else
      return
    end
  end

  # filter on page type or types, and maybe even media flag too!
  def add_type_constraint(arg)
    page_group, page_type, media_type = parse_page_type(arg)

    if media_type
      @conditions << "pages.is_#{media_type} = ?" # safe because media_type is limited by parge_page_type
      @values << true
    elsif page_type
      @conditions << 'pages.type = ?'
      @values << Page.param_id_to_class_name(page_type) # eg 'RateManyPage'
    elsif page_group
      @conditions << 'pages.type IN (?)'
      @values << Page.class_group_to_class_names(page_group) # eg ['WikiPage','SurveyPage']
    else
      # we didn't find either a type or a group for arg
    end
  end

  private

  ##
  ## private guts for building the actual query
  ##

  def options_for_find
    fulltext_filter = [@access_me_clause, @access_target_clause,
      @access_site_clause, @access_filter_clause, @tags].flatten.compact

    if fulltext_filter.any?
      # it is absolutely vital that we MATCH against both access_ids and tags,
      # because this is how the index is specified.
      @conditions << " MATCH(page_terms.access_ids, page_terms.tags) AGAINST (? IN BOOLEAN MODE)"
      @values << fulltext_filter.join(' ')
    end

    conditions = sql_for_conditions
    order      = sql_for_order

    # make the hash
    find_opts = {
      :conditions => conditions,
      :joins => sql_for_joins(conditions),
      :limit => @limit,         # \ manual offset or limit
      :offset => @offset,       # /
      :order => order,
      :include => @include,
      :select => @select || @selects.join(", "),
    }

    find_opts[:group] = sql_for_group(order)
    find_opts[:having] = sql_for_group(order)

    return find_opts
  end

  # the argument is an array, each element assumed to be a
  # separate AND clause, that may be composed of multiple OR clauses.
  # this method unravels the condition tree and converts it to sql.
  def sql_for_boolean_tree(and_clauses)
    # holy crap, i can't believe how ugly this is
    "(" + and_clauses.collect{|or_clause|
      if or_clause.is_a? String
        or_clause
      elsif or_clause.any?
        "(" + or_clause.collect{|condition|
          if condition.is_a? String
            condition
          elsif condition.any?
            condition.join(' AND ')
          end
        }.join(') OR (') + ")"
      else
        "1"
      end
    }.join(') AND (') + ")"
  end

  def sql_for_joins(conditions_string)
    joins = []
    [:user_participations, :group_participations, :page_terms,
      :dailies, :hourlies, :moderated_flags].each do |j|
      if /#{j.to_s}\./ =~ conditions_string
        joins << j
      end
    end
    return joins
  end

  # TODO: make this more generall so it works with all aggregation functions.
  def sql_for_group(order_string)
    if match = /SUM\(.*\)/.match(order_string)
      "pages.id"
    end
  end

  # TODO: make this more generall so it works with all aggregation functions.
  def sql_for_having(order_string)
    if match = /SUM\(.*\)/.match(order_string)
      "#{match} > 0"
    end
  end

  def sql_for_order
    if @order.nil?
      return nil
    else
      if @order.empty? and SearchFilter['descending']
        apply_filter(SearchFilter['descending'], 'updated-at')
      end
      if @order.empty?
        return nil
      else
        return @order.reject(&:blank?).join(', ')
      end
    end
  end

  def add_flow(flow)
    return unless @klass == Page
    if flow.instance_of? Array
      cond = []
      flow.each do |f|
        cond << cond_for_flow(f)
      end
      @conditions << "(" + cond.join(' OR ') + ")"
    else
      @conditions << cond_for_flow(flow)
    end
  end

  def cond_for_flow(flow)
    if flow.nil?
      return 'pages.flow IS NULL'
    elsif flow.instance_of? Symbol
      raise Exception.new('Flow "%s" does not exist' % flow) unless FLOW[flow]
      @values << FLOW[flow]
      return 'pages.flow = ?'
    end
  end

  def sql_for_conditions()
    add_flow( @flow )

    # grab the remaining open clauses
    @or_clauses << @conditions if @conditions.any?
    @and_clauses << @or_clauses
    @and_clauses.reject!(&:blank?)
    Page.quote_sql( [sql_for_boolean_tree(@and_clauses)] + @values )
  end
end

