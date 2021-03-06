require 'rails_helper'

RSpec.describe GameQuestion, type: :model do
  let(:game_question) { create(:game_question, a: 2, b: 1, c: 4, d: 3) }
  context 'game status' do
    describe '#variants' do
      it 'should return variants' do
        expect(game_question.variants).to eq({ 'a' => game_question.question.answer2,
                                               'b' => game_question.question.answer1,
                                               'c' => game_question.question.answer4,
                                               'd' => game_question.question.answer3 })
      end
    end

    describe '#answer_correct?' do
      it 'should return true if answer_correct?' do
        # именно под буквой b в тесте мы спрятали указатель на верный ответ
        expect(game_question.answer_correct?('b')).to be_truthy
      end
    end

    describe '#text & #level' do
      it 'should return correct values' do
        expect(game_question.text).to eq(game_question.question.text)
        expect(game_question.level).to eq(game_question.question.level)
      end
    end

    describe '#correct_answer_key' do
      it 'should return correct key' do
        expect(game_question.correct_answer_key).to eq('b')
      end
    end

    describe '#help_hash' do
      it 'should return correct help_hash' do
        expect(game_question.help_hash).to eq({})

        game_question.help_hash[:some_key1] = 'a1'
        game_question.help_hash['some_key2'] = 'a2'

        expect(game_question.save).to be_truthy

        gq = GameQuestion.find(game_question.id)

        expect(gq.help_hash).to eq({ some_key1: 'a1', 'some_key2' => 'a2' })
      end
    end
  end

  context 'users helpers' do
    describe '#add_audience_help' do
      it 'should add audience help to help hash' do
        expect(game_question.help_hash).not_to include(:audience_help)

        game_question.add_audience_help

        expect(game_question.help_hash).to include(:audience_help)

        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end
    end

    describe '#add_fifty_fifty' do
      it 'should add fifty-fifty help to help hash' do
        expect(game_question.help_hash).not_to include(:fifty_fifty)

        game_question.add_fifty_fifty

        expect(game_question.help_hash).to include(:fifty_fifty)

        ff = game_question.help_hash[:fifty_fifty]
        expect(ff).to include('b')
        expect(ff.size).to eq 2
      end
    end

    describe '#friend_call' do
      it 'should add friend call help to help hash' do
        expect(game_question.help_hash).not_to include(:friend_call)

        game_question.add_friend_call

        expect(game_question.help_hash).to include(:friend_call)

        fc = game_question.help_hash[:friend_call]
        expect(fc).to include('считает, что это вариант')
      end
    end
  end
end
