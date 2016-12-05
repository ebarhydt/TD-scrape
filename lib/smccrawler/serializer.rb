require 'csv'

module Clovercrawler
  class Serializer

    attr_reader :employees

    def initialize(employees)
      @employees = employees
    end

    def generate_csv_files
      csv_files = {}
      employees_per_work_address.each do |work_address, employees|
        csv = CSV.generate do |csv|
          employees.each do |employee|
            csv << serialize_employee(employee)
          end
        end

        csv_files[work_address] = csv
      end

      csv_files
    end

    private

    def serialize_employee(employee)

      birthday = transform_date(employee[:birth_date])
      hired_at = transform_date(employee[:hire_date])
      terminated_at = transform_date(employee[:termination_date])

      data = []
      data << employee[:last_name]
      data << employee[:first_name]
      data << employee[:middle_initial]
      data << '' # Title
      data << '' # TODO: Should we include email?
      data << hired_at
      data << terminated_at
      data << (employee[:pay_type] == 'Salary' ? 'Exempt' : 'Nonexempt')
      data << employee[:pay_amount]
      data << employee[:pay_unit]
      data << employee[:ssn]
      data << (birthday == '' ? '1980/01/01' : birthday)
      data << employee[:street_1]
      data << employee[:street_2]
      data << employee[:city]
      data << employee[:state]
      data << employee[:zip]
      data << employee[:allowances]
      data << employee[:additional_withholdings]
      data << transform_federal_filing_status(employee[:filing_status])
      data += serialize_state_fields(employee)

      # "File new hire report" column is always 0
      data << '0'

      data << employee[:payment_method]

      data
    end

    def employees_per_work_address
      per_location = {}
      employees.each do |employee|
        per_location[employee[:work_address]] ||= []
        per_location[employee[:work_address]] << employee
      end
      per_location
    end

    def serialize_state_fields(employee)
      state = employee[:work_state].upcase

      if EmployeeStateSerializer.const_defined? state
        EmployeeStateSerializer.const_get(state).serialize(employee)
      else
        raise UnsupportedEmployeeStateSerializer(state)
      end
    end

    def transform_federal_filing_status(status)
      if status == 'Do Not Withhold'
        'Exempt from withholding'
      elsif status == 'Head of Household'
        'Married'
      else
        status
      end
    end

    def transform_date(date)
      return '' if (date.nil? || date == '')
      year  = date[-4..-1]
      month   = date[0..1]
      day = date[3..4]

      "#{year}/#{month}/#{day}"
    end
  end
end