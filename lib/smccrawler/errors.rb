module Clovercrawler
	class LoginCredentialsInvalid            < Exception; end
	class LoginAttemptsExceeded              < Exception; end
	class InvalidCompanySelection            < Exception; end
	class MissingEmployeePage                < Exception; end
	class WorkStateParseError                < Exception; end
	class UnsupportedEmployeeWorkState       < Exception; end
	class UnsupportedEmployeeStateSerializer < Exception; end
end