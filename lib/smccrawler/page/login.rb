module Smccrawler
  module Page
    class Login < Base
      LOGIN_URL = 'https://tawkify.mytalkdesk.com/users/sign_in'

      LOGIN_FAILED_ERROR = 'Username and password do not match or you do not have an account yet'
      LOGIN_EXCEEDED_ERROR = 'You have exceeded the permitted number of signin attempts.'

      def login
        browser.goto LOGIN_URL
        browser.text_field(id: 'email').set ''
        browser.text_field(id: 'password').set ''
        browser.input(id: 'but_login').click

        # Watir::Wait.until { browser.title.casecmp(LANDING_PAGE_TITLE) == 0 }
        # assert_logged_in!
      end

      def assert_logged_in!
        if browser.text.include? LOGIN_FAILED_ERROR
          raise LoginCredentialsInvalid
        end

        if browser.text.include? LOGIN_EXCEEDED_ERROR
          raise LoginAttemptsExceeded
        end
      end
    end
  end
end
