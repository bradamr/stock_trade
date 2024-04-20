require 'date'
require 'pg'
require 'httparty'

class StockDataLoader
  attr_reader :market_date, :symbol

  def initialize(symbol, market_date)
    @symbol = symbol
    @market_date = market_date
  end

  def self.load(symbol, market_date)
    new(symbol, market_date).load
  end

  def clear_data
    con = nil
    begin
      con = PG.connect :dbname => 'stock_data', :user => 'xwps'
      con.exec("DELETE from stock_data where symbol = '#{symbol}' and trade_date = '#{market_date}'")
    rescue PG::Error => e
      puts e.message
    ensure
      con.close if con
    end
  end

  def load
    clear_data
    con = nil
    begin
      con = PG.connect :dbname => 'stock_data', :user => 'xwps'
      data = trade_data
      until data['ticks'].nil?
        process_data(con, data)
        offset = data['ticks'].last['t']
        data = trade_data(offset)
      end
    rescue PG::Error => e
      puts e.message
    ensure
      con.close if con
    end
  end

  def trade_data(offset = nil)
    offset_param = offset.nil? ? offset : "&offset=#{offset}"
    historic_data_uri = uri(offset_param)
    response = HTTParty.get(historic_data_uri).body
    JSON.parse(response)
  end

  def uri(params = nil)
    uri = "https://api.polygon.io/v1/historic/quotes/#{symbol}/#{market_date}?apiKey=PKLP4XEVXGIF2YR5NOQI#{params}"
  end

  def process_data(con, data)
    data['ticks'].each do |ticker|
      epoch_time = ticker['t']
      price = ticker['bP']

      next if price.nil?
      con.exec("INSERT INTO stock_data (symbol, price, trade_time, trade_date) VALUES ('#{symbol}',#{price}, '#{epoch_time}', '#{market_date}')")
    end
  end
end

[Time.now.to_date].each do |market_date|
  next if market_date.strftime('%A') =~ /(saturday|sunday)/i
  puts "Loading for date: #{market_date}"
  StockDataLoader.load('ENPH', market_date.strftime('%Y-%m-%d'))
end