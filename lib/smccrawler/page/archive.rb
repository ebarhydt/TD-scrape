require 'csv'
module Smccrawler
  module Page
    class Archive < Base

      def list_links
        # links is an array of hashes, where each element is {:name, :href}
        names = []
        company_names = []
        company_name_guesses = []
        links = []
        (1..10).each do |n|
          link = ''
          begin
            link = browser.link(:xpath => "//*[@id=\"results\"]/li[#{n}]/div/h3/a")

            unless link == ''
              name = link.text
              next if name == 'LinkedIn Member'
              links << link.href
              names << name
            else
              links << ''
              names << ''
            end

            company_name = ''
            company_name = browser.p(:xpath => "//*[@id=\"results\"]/li[#{n}]/div/dl[2]/dd/p").text
              # this is their self-proclaimed title, but we found that 'Current job' works better
              # company_name = browser.p(:xpath => "//*[@id=\"search-results-container\"]/section/div[3]/ul/li[#{n}]/div/div[1]/p").text

            split = company_name.split(' at ')
            company_name_guessed = ''
            company_name_guessed += split[1] if split.size > 1
            company_names << company_name
            company_name_guesses << company_name_guessed

          rescue Watir::Exception::UnknownObjectException
            sleep 5
          end
        end

        leads = names.zip(company_names,company_name_guesses, links)
        leads = leads
        CSV.open("vp_sales5.csv", "a+b") do |csv|
          leads.each do |lead|
            csv << lead
          end
        end
        # NB last page will contain fewer links
        names
      end
    end
  end
end