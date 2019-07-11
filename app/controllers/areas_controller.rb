class AreasController < ApplicationController
  def index
    @areas = Area.all.order(id: :asc)
  end

  def show
    area = Area.includes(:courses).find params[:id]

    @name        = area.name
    @description = area.description
    @courses     = area.courses.order(:name)
  end
end
