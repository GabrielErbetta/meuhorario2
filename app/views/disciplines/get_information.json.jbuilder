json.code @discipline.code
json.name @discipline.name

if @course_discipline
  json.nature @course_discipline.nature
  json.semester @course_discipline.semester if @course_discipline.semester

  json.pre_requisites @pre_requisites do |pre_requisites|
    json.code pre_requisites.pre_discipline.discipline.code
    json.name pre_requisites.pre_discipline.discipline.name
  end

  json.post_requisites @post_requisites do |post_requisites|
    json.code post_requisites.post_discipline.discipline.code
    json.name post_requisites.post_discipline.discipline.name
  end
end