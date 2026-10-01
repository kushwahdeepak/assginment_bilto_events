class ApplicationSubscriptions
  def self.handlers
    EventsDomain.subscriptions
  end
end
