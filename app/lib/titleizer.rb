# Provides methods for manipulating strings
module Titleizer
  UNCAPITALIZED_WORDS = %w[
    de a o que e do da em um para é com não uma os no
    se na por mais as dos como mas foi ao ele das tem à seu sua ou
    ser quando muito há nos já está eu também só pelo pela até isso ela
    entre era depois sem mesmo aos ter seus quem nas me esse eles estão
    você tinha foram essa num nem suas meu às minha têm numa pelos elas
    havia seja qual será nós tenho lhe deles essas esses pelas este fosse
    dele tu te vocês vos lhes meus minhas teu tua teus tuas nosso nossa
    nossos nossas dela delas esta estes estas aquele aquela aqueles aquelas isto
    aquilo estou está estamos estão estive esteve estivemos estiveram estava
    estávamos estavam estivera estivéramos esteja estejamos estejam estivesse estivéssemos
    estivessem estiver estivermos estiverem hei há havemos hão houve houvemos
    houveram houvera houvéramos haja hajamos hajam houvesse houvéssemos houvessem
    houver houvermos houverem houverei houverá houveremos houverão houveria houveríamos
    houveriam sou somos são era éramos eram fui foi fomos foram fora fôramos
    seja sejamos sejam fosse fôssemos fossem for formos forem serei será seremos
    serão seria seríamos seriam tenho tem temos tém tinha tínhamos tinham tive
    teve tivemos tiveram tivera tivéramos tenha tenhamos tenham tivesse tivéssemos
    tivessem tiver tivermos tiverem terei terá teremos terão teria teríamos teriam
  ].freeze

  def self.discipline_name(name)
    name
      .downcase
      .strip
      .remove(/[\t\n\r]/) # Removes tab, new line and carriage return
      .remove('\u00A0') # Remove "non-break space" character
      .gsub(/ {2,}/, ' ') # Removes duplicated spaces
      .gsub(/\p{L}+/) { |word| UNCAPITALIZED_WORDS.include?(word) ? word : word.capitalize } # Capitalizes words
      .gsub(/(\b)(i|ii|iii|iv|v|vi|vii|viii|ix|x|b|c|d|f|g|h)(\b)|((\b)(a|e)$)/i, &:upcase) # Upcases codes
      .gsub(/[;:.,_&*?\/\\]\S/) { |matches| "#{matches[0]} #{matches[1]}" } # Adds spaces after symbols
  end

  def self.course_name(name)
    name
      .downcase
      .strip
      .remove(/[\t\n\r]/) # Removes tab, new line and carriage return
      .remove('\u00A0') # Remove "non-break space" character
      .gsub(/ {2,}/, ' ') # Removes duplicated spaces
      .remove(/ - salvador$/) # Remove redundant "Salvador"
      .gsub(/\p{L}+/) { |word| UNCAPITALIZED_WORDS.include?(word) ? word : word.capitalize } # Capitalizes words
  end

  # Strips space-like characters (including "non-breaking spaces") from a string
  def self.super_strip(string)
    string&.remove(/\A[[:space:]]+|[[:space:]]+\z/, '')
  end
end
