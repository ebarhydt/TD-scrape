require 'cgi'
require 'uri'
require 'rubygems'
require 'nokogiri'
require 'date'
require 'open-uri'

module Smccrawler
  class Crawler < BaseCrawler
    HEADERS_HASH = {"User-Agent" => "Ruby/#{RUBY_VERSION}"}

    attr_accessor :store

    def run
      login_page.login
      browser.goto 'https://tawkify.mytalkdesk.com/#dashboard/recents'
      sleep 5
      reps = ["Josh Hall", "Glenn Norum", "Bea Richards", "Eliza Washington", "Stefan Wenger", "Caitlin Ryvlin", "Camille Presley", "Mary Diaz", "Lani Parker", "Lindsey Perkins", "Kim Helmuth"]
      # reps = ["Josh Hall", "Bea Richards", "Eliza Washington", "Stefan Wenger", "Caitlin Ryvlin", "Camille Presley", "Mary Diaz", "Lani Parker", "Lindsey Perkins"]



      rep_count = {}
      reps.each do |rep|
        rep_count[rep] = 0
      end
      min_call_length = 400
      max_call_length = 3000
      page = 1
      audio_files = []
      while page < 45
        n = 1
        exist = true
        puts "exist is " + exist.to_s
        entries = 1
        while n < 16
          entries += 1
          puts "this is entry #{entries.to_s}"

          puts "--------"
          rep_name = browser.td(xpath:"/html/body/div[1]/div[2]/div[1]/div[2]/div/div[3]/div[1]/div/div/div/div[2]/div[2]/div/table/tbody/tr[#{n}]/td[3]").text
          call_time = browser.td(xpath: "/html/body/div[1]/div[2]/div[1]/div[2]/div/div[3]/div[1]/div/div/div/div[2]/div[2]/div/table/tbody/tr[#{n}]/td[6]").text
          m = Time.parse('00:00')
          t = Time.parse(call_time)
          call_time = (t.to_i - m.to_i)
          if call_time.between?(min_call_length, max_call_length)
            in_call_range = true
          else
            in_call_range = false
          end
          if reps.include? rep_name
            is_sales_rep = true
          else
            is_sales_rep = false
          end
          if is_sales_rep
            if rep_count[rep_name] < 10
              need_more_calls = true
            else
              need_more_calls = false
            end
          else
            need_more_calls = false
          end
          puts "call time is " + call_time.to_s
          puts "Rep name is " + rep_name
          if is_sales_rep && in_call_range && need_more_calls
            puts "Found a rep"
            found_link = false
            n_attempts = 0
            while n_attempts < 3
              sid = nil
              begin
                sleep 2
                puts "about to click link"
                sid = browser.link(xpath:"/html/body/div[1]/div[2]/div[1]/div[2]/div/div[3]/div[1]/div/div/div/div[2]/div[2]/div/table/tbody/tr[#{n}]/td[7]/div/a").attribute_value('data-call-sid')
                rep_count[rep_name] += 1
                puts "rep count is #{rep_count[rep_name]} for #{rep_name}"
                puts "attr value is " + sid
                # browser.goto ('https://tawkify.mytalkdesk.com/#dashboard/recents/' + attr_value)
                sleep 5
                n_attempts = 3
                found_link = true
              rescue
                sleep 10
                n_attempts += 1
                puts "couldn't find sid"
              end
            end
            customer = 'noname'
            begin
              sleep 2
              customer = browser.link(xpath:"/html/body/div[1]/div[2]/div[1]/div[2]/div/div[3]/div[1]/div/div/div/div[2]/div[2]/div/table/tbody/tr[#{n}]/td[2]/a").text
              puts "customer is " + customer
            rescue
              sleep 2
              puts "couldnt retrieve a customer name"
            end
            unless sid.nil?
              entry = {rep_name: rep_name, customer: customer, sid: sid}
              audio_files << entry
              puts "the entry is " + entry.to_s
            end
          end
          n += 1
        end
        n_page_attempts = 0
        while n_page_attempts < 3
          begin
            browser.link(xpath:"/html/body/div[1]/div[2]/div[1]/div[2]/div/div[3]/div[1]/div/div/div/div[2]/div[2]/div/table/tfoot/tr/td/ul/li[13]/a").click # next page of recordings
            n_page_attempts = 3
          rescue
            sleep 10
            n_page_attempts += 1
          end
        end
        page += 1
        puts "page is " + page.to_s
        sleep 5
      end
      audio_files.each do |record| 
        browser.goto ('https://tawkify.mytalkdesk.com/#dashboard/recents/' + record[:sid])
        begin
          browser.link(:text => 'Download').when_present.click
          sleep 5
        rescue
          puts "couldn't find download button"
          next
        end
        sleep 40
        # rep_count[rep_name] += 1
        # puts "#{rep_name} has #{rep_count[rep_name]} calls downloaded so far"
        file_hash = {}
        directory = Dir.home + "/Downloads/"
        Dir.entries(Dir.home + "/Downloads/").map {|f| file_hash[f] = File.mtime(directory + f)}
        downloaded_file = file_hash.sort_by {|k,v| v}[-2]
        downloaded_filename = downloaded_file[0]
        if downloaded_filename.length < 10
          next
        end
        downloaded_filetime = DateTime.parse(downloaded_file[1].to_s)
        current_time = DateTime.now
        elapsed_seconds = ((current_time - downloaded_filetime)* 24 * 60 * 60).to_i
        puts "elapsed seconds is #{elapsed_seconds}"
        if elapsed_seconds < 60
          sleep 5
          filename = downloaded_filename.dup
          filename.slice! ".mp3"
          puts "name looking for is... " + directory + filename + ".mp3"
          File.rename (directory + filename + ".mp3"), Dir.home + "/Documents/clover/clover-audio/tawkify/#{filename}_#{record[:rep_name].gsub(/\s+/, '')}_#{record[:customer]}.mp3"
          puts "done moving the file"
        end
      end
    end

#           if found_link
#             browser.link(xpath:"/html/body/div[1]/div[4]/div/div/div/div[2]/div[2]/div/div/div/div[2]/a").click
#             sleep 5
#             browser.button(:text => 'Close').when_present.click
#             rep_count[rep_name] += 1
#             puts "#{rep_name} has #{rep_count[rep_name]} calls downloaded so far"
#             file_hash = {}
#             directory = Dir.home + "/Downloads/"
#             Dir.entries(Dir.home + "/Downloads/").map {|f| file_hash[f] = File.mtime(directory + f)}
#             downloaded_file = file_hash.sort_by {|k,v| v}[-2]
#             downloaded_filename = downloaded_file[0]
#             downloaded_filetime = DateTime.parse(downloaded_file[1].to_s)
#             current_time = DateTime.now
#             elapsed_seconds = ((current_time - downloaded_filetime)* 24 * 60 * 60).to_i
#             puts "elapsed seconds is #{elapsed_seconds}"
#             if elapsed_seconds < 20
#               filename = downloaded_filename.dup
#               filename.slice! ".mp3"
#               File.rename (directory + filename + ".mp3"), Dir.home + "/Documents/clover/clover-audio/tawkify/#{filename}_#{customer}.mp3"
#               puts "done moving the file"
#             end
#           else
#             puts "the popup didn't come, nothing to click"
#           end
#         else
#           puts "is sales rep is " + is_sales_rep.to_s + "and in call range is " + in_call_range.to_s + "and need more calls is " + need_more_calls.to_s
#         end
#         # divarr = browser.divs(xpath:"/html/body/ng-view/div/div[2]/div/div[2]/div/div[1]/div/div[2]/div[2]/div/div/div")
#         # divarr.each do |div|
#         #   div.click
#         #   sleep 2
#         # end
#         # binding.pry
#         # browser.span(xpath:"/html/body/ng-view/div/div[2]/div/div[2]/div/div[1]/div/div[2]/div[2]/div/div/div[197]/table[1]/tbody/tr/td[4]/span/span[1]").click
#         sleep 2
#         n += 1
#       rescue
#         exist = false
#         # binding.pry
#       end
#     end
#     sleep 3

#   end
# end

    def login_page
      @login_page ||= Page::Login.new(browser)
    end

  end
end







