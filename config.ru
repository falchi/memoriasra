# This file is used by Rack-based servers to start the application, does it work?.

require ::File.expand_path('../config/environment',  __FILE__)
run Bansia::Application
