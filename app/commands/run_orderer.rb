require 'clockwork'
require './config/boot'
require './config/environment'
require 'tzinfo'

module Clockwork
  RETRY_ATTEMPTS = 3

  handler do |job|
    puts "Running #{job}"
  end

  every(1.day, 'Order mealpass', tz: 'America/New_York', at: '23:02') do
    if [5, 6].include?(TZInfo::Timezone.get('America/New_York').now.wday)
      puts 'not ordering today'
    else
      today = (TZInfo::Timezone.get('America/New_York').now.wday + 1)

      User.all.each do |user|
        todays_order_day = user.order_days.find { |od| od.week_day_number == today }

        next unless todays_order_day.scheduled_to_order

        RETRY_ATTEMPTS.times do
          begin
            # remove PhantomJS cookies
            system 'rm $HOME/.local/share/Ofi\ Labs/PhantomJS/*'

            break if Orderer.run(user: user, todays_order_day: todays_order_day)

            rescue Exception => e
              log_entry = "\n===========================\n#{Time.now}\n#{e.message}"
              File.open('log/log.log', 'a') { |file| file << log_entry }
          end
        end
      end
    end
  end
end
