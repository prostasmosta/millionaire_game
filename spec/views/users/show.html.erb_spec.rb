require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'when users looks at his page' do
    let!(:current_user) { assign(:user, build_stubbed(:user, name: 'User')) }

    before do
      view.stub(:current_user) { current_user }
      assign(:games, [build_stubbed(:game)])
      stub_template 'users/_game.html.erb' => 'User game goes here'

      render
    end

    it 'renders player names' do
      expect(rendered).to match 'User'
    end

    it 'renders change password button' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'renders _game' do
      expect(rendered).to match 'User game goes here'
    end
  end

  context 'when users looks at another users page' do
    let!(:user) { assign(:user, build_stubbed(:user, name: 'User1')) }

    before do
      assign(:games, [build_stubbed(:game)])
      stub_template 'users/_game.html.erb' => 'User game goes here'

      render
    end

    it 'renders player names' do
      expect(rendered).to match 'User'
    end

    it 'do not renders change password button' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end

    it 'renders _game' do
      expect(rendered).to match 'User game goes here'
    end
  end
end
