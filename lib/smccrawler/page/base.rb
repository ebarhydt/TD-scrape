module Smccrawler
  module Page
    class Base

      attr_reader :browser
      attr_reader :noko_doc

      def initialize(browser)
        @browser = browser
      end

      def loaded?
        # subclasses to implement
        Raise NotImplementedError
      end

      def wait_for_loaded
        Watir::Wait.until { loaded? }
      end

      private

    end
  end
end