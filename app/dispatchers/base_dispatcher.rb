class BaseDispatcher
  include Wisper::Publisher

  def listeners
    []
  end

  def load_listeners
    listeners.each { |listener| subscribe(listener) }
  rescue LoadError => e
    Rails.logger.warn "Failed to load listener: #{e.message}"
    # Continue without the problematic listener
  rescue NameError => e
    Rails.logger.warn "Listener class not found: #{e.message}"
    # Continue without the problematic listener
  end
end
