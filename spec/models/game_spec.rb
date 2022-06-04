# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    describe '#create_game_for_user!' do
      it 'should create new correct game' do
        # генерим 60 вопросов с 4х запасом по полю level,
        # чтобы проверить работу RANDOM при создании игры
        generate_questions(60)

        game = nil
        # создaли игру, обернули в блок, на который накладываем проверки
        expect {
          game = Game.create_game_for_user!(user)
        }.to change(Game, :count).by(1).and(# проверка: Game.count изменился на 1 (создали в базе 1 игру)
          change(GameQuestion, :count).by(15).and(# GameQuestion.count +15
            change(Question, :count).by(0) # Game.count не должен измениться
          )
        )
        # проверяем статус и поля
        expect(game.user).to eq(user)
        expect(game.status).to eq(:in_progress)
        # проверяем корректность массива игровых вопросов
        expect(game.game_questions.size).to eq(15)
        expect(game.game_questions.map(&:level)).to eq (0..14).to_a
      end
    end
  end

  context 'game status' do
    describe '#current_game_question' do
      it 'returns current question' do
        expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions.first)
      end
    end

    describe '#previous_level' do
      it 'returns previous level' do
        expect(game_w_questions.previous_level).to eq(game_w_questions.current_level - 1)
      end
    end
  end

  # тесты на основную игровую логику
  context 'game mechanics' do
    describe '#answer_current_question!' do
      context 'when answer is wrong' do
        let(:wrong_answer_key) do
          %w[a b c d].grep_v [game_w_questions.current_game_question.correct_answer_key].sample
        end

        before { game_w_questions.answer_current_question!(wrong_answer_key) }

        it 'should finish game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'should assign status fail' do
          expect(game_w_questions.status).to eq(:fail)
        end
      end

      context 'when answer is correct' do
        let!(:level) { game_w_questions.current_level }
        let!(:correct_answer_key) { game_w_questions.current_game_question.correct_answer_key }

        before { game_w_questions.answer_current_question!(correct_answer_key) }

        context 'and question is last' do
          let(:level) { Question::QUESTION_LEVELS.max }
          let(:game_w_questions) { create(:game_with_questions, user: user, current_level: level) }

          it 'should assign final prize' do
            expect(game_w_questions.prize).to eq(Game::PRIZES.last)
          end

          it 'should finish game' do
            expect(game_w_questions.finished?).to be true
          end

          it 'should assign status won' do
            expect(game_w_questions.status).to eq(:won)
          end
        end

        context 'and question is not last' do
          it 'should increase the current level by 1' do
            expect(game_w_questions.current_level).to eq(level + 1)
          end

          it 'should not finish game' do
            expect(game_w_questions.finished?).to be false
          end

          it 'should stay in progress status' do
            expect(game_w_questions.status).to eq(:in_progress)
          end
        end

        context 'and time is over ' do
          let(:game_w_questions) { create(:game_with_questions, user: user, created_at: 1.hour.ago) }

          it 'should finish game' do
            expect(game_w_questions.finished?).to be true
          end

          it 'should assign status timeout' do
            expect(game_w_questions.status).to eq(:timeout)
          end
        end
      end
    end

    describe '#take_money!' do
      it 'should finish the game' do
        q = game_w_questions.current_game_question
        game_w_questions.answer_current_question!(q.correct_answer_key)

        game_w_questions.take_money!

        prize = game_w_questions.prize
        expect(prize).to be > 0
        expect(game_w_questions.status).to eq :money
        expect(game_w_questions.finished?).to be true
        expect(user.balance).to eq prize
      end
    end
  end

  describe '#status' do
    before do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be true
    end

    it 'should :won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq :won
    end

    it 'should :fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq :fail
    end

    it 'should :timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq :timeout
    end

    it 'should :money' do
      expect(game_w_questions.status).to eq :money
    end
  end
end
