module AccountsGenerator
  # split these paragraphs into sentences
  # this is hipster ipsum from https://hipsum.co
  IPSUMS = <<-EOIPSUM.gsub(/\n/,'').split(/[,\.]/).collect(&:strip).compact.freeze
Migas offal succulents af plaid, coloring book whatever letterpress ugh readymade kombucha affogato neutra hot chicken. Wolf bushwick migas XOXO, helvetica neutra chicharrones bicycle rights lomo asymmetrical schlitz bitters leggings. Banjo activated charcoal vape gochujang. Trust fund bicycle rights meditation pinterest thundercats, everyday carry helvetica lumbersexual iPhone copper mug pop-up tote bag pour-over live-edge church-key. Retro man braid skateboard put a bird on it photo booth +1 swag occupy kitsch. Jean shorts skateboard tacos yuccie taxidermy truffaut. Jean shorts gentrify gochujang YOLO.
Subway tile asymmetrical butcher yr hashtag, poke franzen hexagon gastropub fashion axe. Slow-carb hella cornhole trust fund mixtape. XOXO cliche pork belly venmo, roof party fingerstache craft beer. Next level tattooed williamsburg unicorn.
Kickstarter forage chambray hexagon williamsburg green juice edison bulb kogi thundercats. Banjo kickstarter pork belly trust fund master cleanse swag. Organic bitters shabby chic forage tote bag. Single-origin coffee freegan blue bottle, tattooed post-ironic authentic chia artisan cold-pressed. Glossier occupy hella jianbing pabst YOLO fixie godard, PBR&B trust fund kinfolk blue bottle cardigan deep v poke. Edison bulb marfa listicle pour-over try-hard. Literally prism marfa, copper mug meggings schlitz tattooed street art dreamcatcher fixie.
Swag trust fund neutra enamel pin. Occupy VHS fashion axe live-edge celiac. Whatever kitsch XOXO tote bag, salvia flannel kale chips vice. Tacos next level portland, blue bottle letterpress sartorial enamel pin ennui deep v drinking vinegar chia raw denim occupy gentrify. Woke bicycle rights cloud bread tacos butcher wayfarers +1 asymmetrical fanny pack hella deep v iceland. Synth keytar post-ironic biodiesel.
Fingerstache kickstarter photo booth asymmetrical. Pinterest swag vegan celiac vape, waistcoat biodiesel mixtape beard jean shorts salvia photo booth. Hexagon flannel lyft, pabst taxidermy brunch godard. Pinterest forage flexitarian activated charcoal, meditation hammock helvetica intelligentsia portland fanny pack salvia. 90's fashion axe humblebrag typewriter marfa gastropub. Whatever flexitarian seitan pinterest pabst thundercats kickstarter cornhole vaporware deep v. Distillery vaporware four loko gentrify try-hard salvia blog.
  EOIPSUM

  class << self
    def generate_accounts_for_user(user)
      Account.transaction do
        3.times do
          Account.create! owner: user,
                          currency: 'GBP',
                          account_type: 'Personal',
                          account_subtype: %w{ChargeCard CreditCard CurrentAccount EMoney Savings}.shuffle.first,
                          scheme_name: 'SortCodeAccountNumber',
                          identification: '%014d' % [rand(99999999999999)]
        end
      end

      user.accounts.each do |account|
        Transaction.transaction do
          newest_transaction = nil
          100.downto(1) do |i|
            amount, balance, credit_or_debit = nil

            # don't let the balance go negative
            if newest_transaction
              amount = rand(newest_transaction.balance.to_i + (1000 * 100)) - newest_transaction.balance.to_i
              credit_or_debit = amount < 0 ? Transaction::DEBIT : Transaction::CREDIT
              amount = Money.new(amount.abs, account.currency)
              balance = newest_transaction.balance + (credit_or_debit == Transaction::DEBIT ? amount * -1 : amount)
            else
              amount = Money.new(rand(5000 * 100), account.currency)
              balance = amount
              credit_or_debit = Transaction::CREDIT
            end

            newest_transaction = Transaction.create! account: account,
                                                     amount: amount,
                                                     balance: balance,
                                                     credit_or_debit: credit_or_debit,
                                                     booked_at: (i * 3).days.ago,
                                                     description: IPSUMS.shuffle.first,
                                                     merchant_name: IPSUMS.shuffle.first.split(/\s+/).take(3).join(' '),
                                                     merchant_code: "5932",
                                                     during_generation: true
          end
        end

        starting_at = account.transactions.oldest_first.first.booked_at
        ending_at = starting_at.end_of_quarter.tomorrow.beginning_of_quarter # ending_at is not inclusive
        last_ending_at = DateTime.now.beginning_of_quarter
        Statement.transaction do
          begin
            Statement.create! account: account,
                              starting_at: starting_at,
                              ending_at: ending_at,
                              created_at: ending_at.tomorrow
            starting_at = ending_at
            ending_at = ending_at.next_quarter
          end while ending_at <= last_ending_at
        end
      end
    end
  end
end
