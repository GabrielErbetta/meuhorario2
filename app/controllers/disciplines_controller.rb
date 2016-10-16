class DisciplinesController < ApplicationController

  def ajax_search
    @disciplines = Discipline.where 'name ILIKE ? or code ILIKE ?', "%#{params[:pattern]}%", "%#{params[:pattern]}%"
  end
end