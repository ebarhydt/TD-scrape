module Smccrawler
  class BaseCrawler
    class << self
      def run
        with_browser do |browser|
          new(browser).run
        end
      end

      private

      def with_browser
        browser = Watir::Browser.new :chrome
        begin
          yield(browser)
        #rescue Exception => e
            # binding.pry
        ensure
          browser.close
        end
      end
    end

    attr_reader :browser

    def initialize(browser)
      @browser = browser
    end
  end
end