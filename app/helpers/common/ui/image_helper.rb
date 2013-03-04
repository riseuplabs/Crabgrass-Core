##
## Here in lies all the helpers for displaying icons, avatars, spinners,
## and various images.
##

module Common::Ui::ImageHelper

  IMAGE_SIZES = Hash.new(200).merge({
    :small  => 64,
    :medium => 200,
    :large  => 500
  }).freeze

  ##
  ## ICON
  ##

  #
  # for example: icon_tag('pencil')
  #
  # currently, any 'size' argument other than the default will not display well.
  #
  def icon_tag(icon, size = 16)
    content_tag :i, ' ', :class => "small_icon #{icon}_#{size}"
  end

#  def pushable_icon_tag(icon, size = 16, id = nil)
#    content_tag :button, '', :class => "icon_#{size} #{icon}_#{size}", :style=>'cursor:pointer', :id => id
#  end


  ##
  ## PAGES
  ##
  ## every page has an icon.
  ##

  ## returns the img tag for the page's icon
  def page_icon(page)
    content_tag :div, '&nbsp;'.html_safe, :class => "page_icon #{page.icon}_16"
  end

  ##
  ## SPINNER
  ##
  ## spinners are animated gifs that are used to show progress.
  ## see JavascriptHelper for showing and hiding spinners.
  ##

  def spinner(id, options={})
    display = ("display:none;" unless options[:show])
    options = {:spinner=>"spinner.gif", :style=>"#{display} vertical-align:middle;", :class => 'spin'}.merge(options)
    if options[:text]
      "<span id='#{spinner_id(id)}' style='#{display}'><img src='/images/#{options[:spinner]}' style='vertical-align:middle' alt='' class='#{options[:class]}' /> #{h(options[:text])} </span>"
    else
      "<img src='/images/#{options[:spinner]}' style='#{options[:style]}' id='#{spinner_id(id)}' alt='' class='#{options[:class]}' />"
    end.html_safe
  end

  def spinner_id(id)
    if id.is_a? ActiveRecord::Base
      id = dom_id(id, 'spinner')
    else
      "#{id.to_s}_spinner"
    end
  end

  def spinner_icon_on(icon, id)
    target = id ? "$('#{id}')" : 'eventTarget(event)'
    "replaceClassName(#{target}, '#{icon}_16', 'spinner_icon')"
  end

  def spinner_icon_off(icon, id)
    target = id ? "$('#{id}')" : 'eventTarget(event)'
    "replaceClassName(#{target}, 'spinner_icon', '#{icon}_16')"
  end

  def big_spinner()
    content_tag :div, '', :style => "background: white url(/images/spinner-big.gif) no-repeat 50% 50%; height: 5em;", :class => 'spin'
  end

  # we can almost do this to trick ie into working with event.target,
  # which would eliminate the need for random ids.
  #
  # but it doesn't quite work, because for :complete of ajax, window.event
  # is not right
  #
  #  function eventTarget(event) {
  #    event = event || window.event; // IE doesn't pass event as argument.
  #    return(event.target || event.srcElement); // IE doesn't use .target
  #  }
  #
  # however, this can be used for non-ajax js.


  ##
  ## ASSET THUMBNAILS
  ##

  #
  # creates an img tag for a thumbnail, optionally scaling the image or cropping
  # the image to meet new dimensions (using html/css, not actually scaling/cropping)
  #
  # eg: thumbnail_img_tag(asset, :medium, :crop => '22x22')
  #
  # thumbnail_name: one of :small, :medium, :large
  #
  # options:
  #  * :crop   -- the img is first scaled, then cropped to allow it to
  #               optimally fit in the cropped space.
  #  * :scale  -- the img is scaled, preserving proportions
  #  * :crop!  -- crop, even if there is no known height and width
  #
  # note: if called directly, thumbnail_img_tag does not actually do the
  #       cropping. rather, it generate a correct img tag for use with
  #       link_to_asset.
  #
  def thumbnail_img_tag(asset, thumbnail_name, options={}, html_options={})
    thumbnail = asset.thumbnail(thumbnail_name)
    if thumbnail and thumbnail.height and thumbnail.width
      options[:crop] ||= options[:crop!]
      if options[:crop] or options[:scale]
        target_width, target_height = (options[:crop]||options[:scale]).split(/x/).map(&:to_f)
        if target_width >= thumbnail.width and target_height >= thumbnail.height
          # thumbnail is actually _smaller_ than our target area
          margin_x = ((target_width - thumbnail.width) / 2)
          margin_y = ((target_height - thumbnail.height) / 2)
          img = image_tag(thumbnail.url, html_options.merge(:size => "#{thumbnail.width}x#{thumbnail.height}",
            :style => "padding: #{margin_y}px #{margin_x}px;"))
        elsif options[:crop]
          # extra thumbnail will be hidden by overflow:hidden
          ratio  = [target_width / thumbnail.width, target_height / thumbnail.height].max
          ratio  = [1, ratio].min
          height = (thumbnail.height * ratio).round
          width  = (thumbnail.width * ratio).round
          img = image_tag(thumbnail.url, html_options.merge(:size => "#{width}x#{height}"))
        elsif options[:scale]
          # set image tag to use new scale
          ratio  = [target_width / thumbnail.width, target_height / thumbnail.height, 1].min
          height = (thumbnail.height * ratio).round
          width  = (thumbnail.width * ratio).round
          image_tag(thumbnail.url, html_options.merge(:size => "#{width}x#{height}"))
        end
      else
        image_tag(thumbnail.url, html_options.merge(:size => "#{thumbnail.width}x#{thumbnail.height}"))
      end
    elsif options[:crop!]
      target_width, target_height = options[:crop!].split(/x/).map(&:to_f)
      img = thumbnail_or_icon(asset, thumbnail, target_width, target_height, html_options)
    else
      thumbnail_or_icon(asset, thumbnail, html_options)
    end
  end

  # links to an asset with a thumbnail preview
  def link_to_asset(asset, thumbnail_name, options={})
    thumbnail = asset.thumbnail(thumbnail_name)
    img = thumbnail_img_tag(asset, thumbnail_name,options)
    if size = (options[:crop]||options[:scale]||options[:crop!])
      target_width, target_height = size.split(/x/).map(&:to_f)
    elsif thumbnail and thumbnail.width and thumbnail.height
      target_width = thumbnail.width
      target_height = thumbnail.height
    else
      target_width = 32;
      target_height = 32;
    end
    options[:class] ||= 'thumbnail'
    options[:title] ||= asset.filename
    options[:style]   = "height:#{target_height}px;width:#{target_width}px"
    url     = options[:url] || asset.url
    # options[:method] ||= 'get'
    # span = content_tag(:span, asset.filename)
    if options[:xhr]
      link_to_remote img, {:url => url}, options.slice(:class, :title, :style)
    else
      link_to img, url, options.slice(:class, :title, :style)
    end
  end

  # links to an asset with a thumbnail preview
  def old_link_to_asset(asset, thumbnail_name, options={})
    thumbnail = asset.thumbnail(thumbnail_name)
    img = thumbnail_img_tag(asset, thumbnail_name,options)
    if size = (options[:crop]||options[:scale]||options[:crop!])
      target_width, target_height = size.split(/x/).map(&:to_f)
    elsif thumbnail and thumbnail.width and thumbnail.height
      target_width = thumbnail.width
      target_height = thumbnail.height
    else
      target_width = 32;
      target_height = 32;
    end
    style   = "height:#{target_height}px;width:#{target_width}px"
    klass   = options[:class] || 'thumbnail'
    url     = options[:url] || asset.url
    method  = options[:method] || 'get'
    link_to img, url, :class => klass, :title => asset.filename, :style => style, :method => method
  end


  def thumbnail_or_icon(asset, thumbnail, width=nil, height=nil, html_options={})
    if thumbnail
      image_tag(thumbnail.url, html_options)
    else
      mini_icon_for(asset, width, height)
    end
  end

  def icon_for(asset)
    image_tag "/images/png/16/#{asset.big_icon}.png", :style => 'vertical-align: middle'
  end

  def mini_icon_for(asset, width=nil, height=nil)
    if width.nil? or height.nil?
      image_tag "/images/png/16/#{asset.small_icon}.png", :style => 'vertical-align: middle;'
    else
      image_tag "/images/png/16/#{asset.small_icon}.png", :style => "margin: #{(height-22)/2}px #{(width-22)/2}px;"
    end
  end

  ##
  ## AGNOSTIC MEDIA
  ##

  def display_media(media, size=:medium)
    if media.respond_to?(:is_image?) and media.is_image?
      if media.respond_to?(:thumbnail)
        thumbnail = media.thumbnail(size)
        if thumbnail.nil? or thumbnail.failure?
          dims = case size
            when :small  then '64x64'
            when :medium then '200x200'
            when :large  then '500x500'
          end
          image_tag('/images/ui/corrupted/corrupted.png', :size => dims)
        else
          image_tag(thumbnail.url, :height => thumbnail.height, :width => thumbnail.width)
        end
      else
        # not sure what we are trying to display
      end
    elsif media.respond_to?(:is_video?) and media.is_video?
      media.build_embed
    end
  end

  ##
  ## PICTURES
  ##

  #
  # Displays a Picture object as the background image of an empty div.
  #
  # 'size' can be either a Symbol :small, :medium, :large, or a Hash
  # of the format used by Picture geometry (see picture.rb)
  #
  def picture_tag(picture, size=:medium)
    content_tag :div, '', :style => picture_style(picture, size)
  end

  def picture_style(picture, size=:medium)
    if size.is_a? Symbol
      pixels = IMAGE_SIZES[size];
      geometry = {:max_width => pixels, :min_width => pixels, :max_height => pixels*2}
    else
      geometry = size
    end
    picture.add_geometry!(geometry)
    width, height = picture.size(geometry)
    "width: 100%%; max-width: %spx; height: %spx; background: url(%s)" % [width, height, picture.url(geometry)]
  end

end
