class NotificationThread
  TITLES = {
      price_limit: "Minimum Price Limit Exceeded",
      highest_price_limit: "Highest Price Limit Exceeded",
      purchase:    "Stock Purchase",
      sale:        "Stock Sale"
  }.freeze

  def self.notify(key, message)
    new.notify(key, message)
  end

  def notify(key, message)
    %x(osascript -e 'display notification \"#{message}\" with title \"#{title(key)}\"')
  end

  private

  def title(key)
    TITLES[key]
  end
end