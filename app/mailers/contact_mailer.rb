class ContactMailer < ApplicationMailer
  default from: 'contato@meuhorario.com'

  def contact data
    @name = data['name']
    @email = data['email']
    @message = data['message']

    mail(to: 'gabrielerbetta@gmail.com', subject: 'Nova sugestão no MeuHorario')
  end
end
