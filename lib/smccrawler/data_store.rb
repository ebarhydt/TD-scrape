require 'zip/zip'

module Clovercrawler
  class DataStore

    attr_accessor :browser, :company_name_safe, :output_dir
    attr_accessor :company_folder_path, :company_employees_folder_path

    def initialize(browser, output_dir, folder_name)
      @browser = browser
      @folder_name_safe = folder_name.gsub(/\s+/, '_').tr('.', '').tr(',', '').downcase
      @output_dir = output_dir

      prepare_folders
    end

    def previously_crawled?
      Dir[File.join(@company_folder_path, '**', '*.html')].any?
    end

    def save_csv(work_address, csv)
      filename = "#{work_address.gsub /[^a-z0-9\-]+/i, '_'}.csv"
      path = File.join(@company_folder_path, filename)
      File.open(path, 'w') { |file| file.write(csv) }
      puts "Saved #{path}..."
    end

    def save_page(page_name, path=@company_folder_path)
      File.open(File.join(path, page_name), 'w') { |file| file.write(browser.html) }
    end

    def save_employee_page(employee_id, page_name)
      save_page("#{page_name}.html", employee_folder(employee_id))
    end

    def load_company_page(page_name)
      navigate_ignore_js_alerts("file://#{File.absolute_path(File.join(company_folder_path, page_name))}")
    end

    def load_employee_page(employee_id, name)
      employee_file_path =  File.absolute_path(File.join(employee_folder(employee_id), "#{name}.html"))
      raise MissingEmployeePage unless File.exist?(employee_file_path)

      navigate_ignore_js_alerts("file://#{employee_file_path}")
    end

    def employee_ids
      Dir.entries(@company_employees_folder_path).select do |entry|
        folder = File.join(@company_employees_folder_path, entry)
        File.directory?(folder) && !(entry =='.' || entry == '..')
      end
    end

    def create_csv_zip(zip_file_name)
      zip_path = File.absolute_path(File.join(@folder_path, zip_file_name))
      csvs_to_zip = Dir[File.absolute_path(File.join(@company_folder_path, "*.csv"))]

      Zip::ZipFile.open(zip_path, Zip::ZipFile::CREATE) do |zip_file|
        csvs_to_zip.each do |csv_to_zip|
          zip_file.add(File.basename(csv_to_zip), csv_to_zip) { true }
        end
      end

      zip_path
    end

    private

    def navigate_ignore_js_alerts(url)
      begin
        browser.goto url
      rescue Selenium::WebDriver::Error::UnhandledAlertError
        browser.alert.ok
      end
    end

    def employee_folder(employee_id)
      employee_folder_path = File.join(@company_employees_folder_path, employee_id)
      try_mkdir(employee_folder_path)
      employee_folder_path
    end

    def prepare_folders
      @folder_path = File.join(@output_dir, folder_name_safe)
      Dir.mkdir(path) unless File.directory?(path)
    end
  end
end