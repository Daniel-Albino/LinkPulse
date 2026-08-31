class RedirectsController < ApplicationController
  before_action :set_link, only: [:show]

  def show
    if @link
      ClickEvent.create(link: @link)
      redirect_to @link.url, allow_other_host: true
    else
      render plain: "Link not found", status: :not_found
    end
  end

  private

  def set_link
    @link = Link.find_by(short_code: params[:short_code])
  end
end
