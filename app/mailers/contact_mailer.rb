class ContactMailer < ApplicationMailer
  default from: 'contato@meuhorario.com'

  def contact
    @name = params[:from_name]
    @email = params[:from_email]
    @message = params[:message]

    mail(
      to: ENV.fetch('MAIL_TO', 'foo@bar.com'),
      subject: 'Nova sugestão no MeuHorario'
    )
  end
end
