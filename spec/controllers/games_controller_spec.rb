require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, is_admin: true) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  describe '#show' do
    context 'Anon' do
      it 'should kick from #show' do
        get :show, id: game_w_questions.id

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'Usual users' do
      before { sign_in user } # логиним юзера users с помощью спец. Devise метода sign_in

      it 'should show the game' do
        get :show, id: game_w_questions.id
        game = assigns(:game) # вытаскиваем из контроллера поле @game
        expect(game.finished?).to be false
        expect(game.user).to eq(user)

        expect(response.status).to eq(200)
        expect(response).to render_template('show')
      end

      it '#show alien game' do
        alien_game = create(:game_with_questions)
        get :show, id: alien_game.id

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#create' do
    context 'Anon' do
      it 'should kick from #create' do
        post :create

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'Usual users' do
      before { sign_in user }

      it 'should create game' do
        # сперва накидаем вопросов, из чего собирать новую игру
        generate_questions(15)

        post :create
        game = assigns(:game) # вытаскиваем из контроллера поле @game

        expect(game.finished?).to be false
        expect(game.user).to eq(user)
        # и редирект на страницу этой игры
        expect(response).to redirect_to(game_path(game))
        expect(flash[:notice]).to be
      end

      it 'try to create second game' do
        expect(game_w_questions.finished?).to be_falsey
        expect { post :create }.to change(Game, :count).by(0)

        game = assigns(:game)
        expect(game).to be_nil

        expect(response).to redirect_to(game_path(game_w_questions))
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#answer' do
    context 'Anon' do
      before do
        put :answer, id: game_w_questions.id,
            letter: game_w_questions.current_game_question.correct_answer_key
      end

      it 'should response' do
        expect(response.status).not_to eq(200)
      end

      it 'should redirect' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should show alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'Usual users' do
      before { sign_in user }

      context 'correct answer' do
        let(:game) { assigns(:game) }

        before do
          put :answer, id: game_w_questions.id,
              letter: game_w_questions.current_game_question.correct_answer_key
        end

        it 'should not finish the game' do
          expect(game.finished?).to be false
        end

        it 'should get to next level' do
          expect(game.current_level).to be > 0
        end

        it 'should redirect' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'should not show flash' do
          expect(flash.empty?).to be true
        end
      end

      context 'uncorrect answer' do
        let(:game) { assigns(:game) }
        let(:c) { game_w_questions.current_level }

        before do
          put :answer, id: game_w_questions.id, letter: 'c'
        end

        it 'should finish the game' do
          expect(game.finished?).to be true
        end

        it 'should not go to next level' do
          expect(game.current_level).to be > c - 1
        end

        it 'should redirect' do
          expect(response).to redirect_to(user)
        end

        it 'should show flash' do
          expect(flash.empty?).to be false
        end
      end
    end
  end

  describe '#take_money' do
    context 'Anon' do

      it 'kick from #take_money' do
        put :take_money, id: game_w_questions.id

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'Usual users' do
      before { sign_in user }

      it 'takes money' do
        game_w_questions.update_attribute(:current_level, 2)
        put :take_money, id: game_w_questions.id
        game = assigns(:game)

        expect(game.finished?).to be true
        expect(game.prize).to eq(200)

        user.reload
        expect(user.balance).to eq(200)

        expect(response).to redirect_to(user_path(user))
        expect(flash[:warning]).to be
      end
    end
  end

  describe '#help' do
    context 'Anon' do
      before { put :help, id: game_w_questions.id }

      it 'should not response' do
        expect(response.status).not_to eq(200)
      end

      it 'should redirect' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should show alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'Usual users' do
      let(:game) { assigns(:game) }

      before { sign_in user }

      context 'use audience help' do
        before do
          expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
          expect(game_w_questions.audience_help_used).to be false

          put :help, id: game_w_questions.id, help_type: :audience_help
        end

        it 'game should not be finished' do
          expect(game.finished?).to be false
        end

        it 'should use audience help' do
          expect(game.audience_help_used).to be true
        end

        it 'audience help hash should be' do
          expect(game.current_game_question.help_hash[:audience_help]).to be
        end

        it 'audience help hash should contain these keys' do
          expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        end

        it 'should redirect' do
          expect(response).to redirect_to(game_path(game))
        end
      end

      context 'use 50/50' do
        before do
          expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
          expect(game_w_questions.fifty_fifty_used).to be_falsey

          put :help, id: game_w_questions.id, help_type: :fifty_fifty
        end

        it 'game should not be finished' do
          expect(game.finished?).to be false
        end

        it 'should use 50/50 help' do
          expect(game.fifty_fifty_used).to be true
        end

        it '50/50 help hash should be' do
          expect(game.current_game_question.help_hash[:fifty_fifty]).to be
        end

        it '50/50 help hash should contain correct key' do
          expect(game.current_game_question.help_hash[:fifty_fifty]).to include(game.current_game_question
                                                                                    .correct_answer_key)
        end

        it '50/50 help hash should have current size' do
          expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq 2
        end

        it 'should redirect' do
          expect(response).to redirect_to(game_path(game))
        end
      end

      context 'use friend call' do
        before do
          expect(game_w_questions.current_game_question.help_hash[:friend_call]).not_to be
          expect(game_w_questions.friend_call_used).to be false

          put :help, id: game_w_questions.id, help_type: :friend_call
        end

        it 'game should not be finished' do
          expect(game.finished?).to be false
        end

        it 'should use friend call help' do
          expect(game.friend_call_used).to be true
        end

        it 'should add friend call to help hash' do
          expect(game.current_game_question.help_hash).to include(:friend_call)
        end

        it 'should add friend call help with answer key' do
          expect(%w[A B C D]).to include(game.current_game_question.help_hash[:friend_call].last)
        end

        it 'game should not be finished' do
          expect(game.finished?).to be false
        end

        it 'should redirect' do
          expect(response).to redirect_to(game_path(game))
        end
      end
    end
  end
end
