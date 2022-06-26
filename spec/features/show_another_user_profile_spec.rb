require 'rails_helper'

RSpec.feature 'looks at another users profile', type: :feature do
  let(:user) { create :user }

  let(:game_w_questions) { create(:game, user: user) }

  before(:each) do
    login_as :user
  end
end