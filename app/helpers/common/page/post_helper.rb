module Common::Page::PostHelper

  protected

  #
  # pagination links for posts. On pages, we call
  # the pagination param 'posts', but otherwise we call
  # it 'pages'.
  #
  def post_pagination_links(posts)
    if posts.any? && posts.respond_to?(:total_pages)
      if @page
        param_name = 'posts'
      else
        param_name = 'page'
      end
      content_tag :div do
        will_paginate(posts, class: "pagination",
          param_name: param_name,
          renderer: LinkRenderer::Page,
          previous_label: :pagination_previous.t,
          next_label: :pagination_next.t
        )
      end
    end
  end


end

