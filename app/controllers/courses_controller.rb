class CoursesController < ApplicationController

  def show
    @course = Course.find_by_code(params[:id]).name
  end

end