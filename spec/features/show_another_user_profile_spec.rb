require 'rails_helper'

RSpec.feature 'looks at another users profile', type: :feature do
  let(:user) { FactoryBot.create :user }

  let(:game_w_questions) { FactoryBot.create(:game, user: user) }

  # Перед началом любого сценария нам надо авторизовать пользователя
  before(:each) do
    login_as :user
  end

  # scenario 'successfully' do
    # visit '/'

    # В процессе работы можно использовать
    # save_and_open_page
    # но в конечном коде (который вы кладете в репозиторий)
    # этого кода быть не должно, также, как и byebug
  # end
end