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

    context 'Usual user' do
      before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

      it 'should show the game' do
        get :show, id: game_w_questions.id
        game = assigns(:game) # вытаскиваем из контроллера поле @game
        expect(game.finished?).to be false
        expect(game.user).to eq(user)

        expect(response.status).to eq(200)
        expect(response).to render_template('show')
      end

      it '#show alien game' do
        alien_game = FactoryBot.create(:game_with_questions)
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

    context 'Usual user' do
      before(:each) { sign_in user }

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
      it 'should kick from #answer' do
        put :answer, id: game_w_questions.id,
            letter: game_w_questions.current_game_question.correct_answer_key

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'Usual user' do
      before(:each) { sign_in user }

      context 'correct answer' do
        it 'should accept answer' do
          # передаем параметр params[:letter]
          put :answer, id: game_w_questions.id,
              letter: game_w_questions.current_game_question.correct_answer_key
          game = assigns(:game)

          expect(game.finished?).to be false
          expect(game.current_level).to be > 0
          expect(response).to redirect_to(game_path(game))
          expect(flash.empty?).to be true
        end
      end

      context 'uncorrect answer' do
        it 'should not accept answer' do
          c = game_w_questions.current_level
          put :answer, id: game_w_questions.id,
              letter: 'c'
          game = assigns(:game)

          expect(game.finished?).to be true
          expect(game.current_level).to be > c - 1
          expect(response).to redirect_to(user)
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

    context 'Usual user' do
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
      it 'kick from #help' do
        put :help, id: game_w_questions.id

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'Usual user' do
      before { sign_in user }

      it 'uses audience help' do
        # сперва проверяем что в подсказках текущего вопроса пусто
        expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
        expect(game_w_questions.audience_help_used).to be false

        # фигачим запрос в контроллер с нужным типом
        put :help, id: game_w_questions.id, help_type: :audience_help
        game = assigns(:game)

        # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
        expect(game.finished?).to be false
        expect(game.audience_help_used).to be true
        expect(game.current_game_question.help_hash[:audience_help]).to be
        expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        expect(response).to redirect_to(game_path(game))
      end

      it 'uses 50/50 help' do
        expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
        expect(game_w_questions.fifty_fifty_used).to be_falsey

        put :help, id: game_w_questions.id, help_type: :fifty_fifty
        game = assigns(:game)

        expect(game.finished?).to be false
        expect(game.fifty_fifty_used).to be true
        expect(game.current_game_question.help_hash[:fifty_fifty]).to be
        expect(game.current_game_question.help_hash[:fifty_fifty]).to include(game.current_game_question
                                                                                  .correct_answer_key)
        expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq 2
        expect(response).to redirect_to(game_path(game))
      end
    end
  end
end
