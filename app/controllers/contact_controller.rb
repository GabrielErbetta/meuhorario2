# Handles contact page and form submission
class ContactController < ApplicationController
  # GET
  def show; end

  # POST
  def submit
    if !verify_recaptcha
      flash[:alert] = 'Erro ao verificar o captcha. Tente novamente.'
    elsif !ContactMailer.with(contact_params).contact.deliver_now
      flash[:alert] = 'Erro ao enviar email. ' \
                      'Tente novamente ou entre em contato mandando um email para meuhorarioufba@gmail.com'
    else
      flash[:success] = 'Mensagem enviada com sucesso.'
    end

    redirect_to action: :show
  end

  private

  def contact_params
    params.require(:contact).permit(:from_name, :from_email, :message)
  end
end
