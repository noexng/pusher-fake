Gem::Specification.new do |s|
  s.name        = "pusher-fake"
  s.version     = "1.5.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tristan Dunn"]
  s.email       = "hello@tristandunn.com"
  s.homepage    = "https://github.com/tristandunn/pusher-fake"
  s.summary     = "A fake Pusher server for development and testing."
  s.description = "A fake Pusher server for development and testing."
  s.license     = "MIT"

  s.files        = Dir["lib/**/*"].to_a + Dir['bin/*'].to_a
  s.test_files   = Dir["spec/**/*"].to_a
  s.executables  = "pusher-fake"
  s.require_path = "lib"

  s.add_dependency "em-http-request", "~> 1.1"
  s.add_dependency "em-websocket",    "~> 0.5"
  s.add_dependency "thin",            "~> 1.5"
  s.add_dependency "multi_json",      "~> 1.6"
  s.add_dependency "thor",            '~> 0.19'

  s.add_development_dependency "capybara-webkit", "1.8.0"
  s.add_development_dependency "pusher",          "0.17.0"
  s.add_development_dependency "rake",            "10.5.0"
  s.add_development_dependency "rspec",           "3.4.0"
  s.add_development_dependency "sinatra",         "1.4.7"
  s.add_development_dependency "yard",            "0.8.7.6"
end
