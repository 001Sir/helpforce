# Fix for Heroku deployment - force clean build
class Dispatcher
  include Singleton

  attr_reader :async_dispatcher, :sync_dispatcher

  def self.dispatch(event_name, timestamp, data, async = false)
    Rails.configuration.dispatcher.dispatch(event_name, timestamp, data, async)
  end

  def initialize
    @sync_dispatcher = SyncDispatcher.new
    @async_dispatcher = AsyncDispatcher.new
  rescue LoadError => e
    Rails.logger.error "Failed to initialize dispatcher: #{e.message}"
    # Fallback to basic functionality
    @sync_dispatcher = BaseDispatcher.new
    @async_dispatcher = BaseDispatcher.new
  rescue NameError => e
    Rails.logger.error "Dispatcher class not found: #{e.message}"
    # Fallback to basic functionality
    @sync_dispatcher = BaseDispatcher.new
    @async_dispatcher = BaseDispatcher.new
  end

  def dispatch(event_name, timestamp, data, _async = false)
    @sync_dispatcher.dispatch(event_name, timestamp, data)
    @async_dispatcher.dispatch(event_name, timestamp, data)
  end

  def load_listeners
    @sync_dispatcher.load_listeners
    @async_dispatcher.load_listeners
  end
end
