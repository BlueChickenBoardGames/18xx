# frozen_string_literal: true

require_relative '../../../step/share_buying'

module Engine
  module Game
    module G18EU
      module MinorExchange
        include Engine::Step::ShareBuying

        def merge_minor!(minor, corporation, source)
          maybe_remove_token(minor, corporation)

          if source == corporation
            transfer_treasury(minor, corporation)
            transfer_trains(minor, corporation)
          else
            transfer_treasury(minor, @game.bank)
            transfer_trains(minor, @game.depot)
          end

          @game.close_corporation(minor, quiet: false) unless @round.pending_acquisition
          minor.close! unless @round.pending_acquisition
        end

        def maybe_remove_token(minor, corporation)
          return minor.tokens.first.remove! unless corporation.tokens.first&.used

          @round.pending_acquisition = { minor: minor, corporation: corporation }
        end

        def exchange_share(minor, corporation, source)
          @game.log << "#{minor.owner.name} exchanges #{minor.name} for a "\
                       "10% share of #{corporation.name}"

          bundle = if source == corporation
                     corporation.treasury_shares.first.to_bundle
                   else
                     @game.share_pool.shares_of(corporation).first.to_bundle
                   end

          buy_shares(minor.owner, bundle, exchange: true)
        end

        def transfer_treasury(source, destination)
          return unless source.cash.positive?

          @game.log << "#{destination.name} takes #{@game.format_currency(source.cash)}"\
                       " from #{source.name} remaining cash"

          source.spend(source.cash, destination)
        end

        def transfer_trains(source, destination)
          return unless source.trains.any?

          transferred = []
          if destination == @game.depot
            source.trains.each do |train|
              @game.depot.reclaim_train(train)
              transferred << train
            end
          else
            transferred = @game.transfer(:trains, source, destination)
          end

          @game.log << "#{destination.name} takes #{transferred.map(&:name).join(', ')}"\
                       " train#{transferred.one? ? '' : 's'} from #{source.name}"
        end
      end
    end
  end
end
