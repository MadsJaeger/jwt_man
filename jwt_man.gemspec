require_relative 'lib/jwt_man/version'

Gem::Specification.new do |spec|
  spec.name        = 'jwt_man'
  spec.version     = JwtMan::VERSION
  spec.authors     = ['Mads Jæger']
  spec.email       = ['madshjaeger@gmai.com']
  spec.homepage    = 'https://github.com/MadsJaeger/jwt_man'
  spec.summary     = 'JWT Manager for Rails'
  spec.description = 'JWTs with refresh tokens.'
  spec.license     = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/changelog"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,spec,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end
  spec.test_files = Dir['spec/**/*']

  spec.add_dependency 'jwt', '~> 2.2'
  spec.add_dependency 'rails'
  spec.add_dependency 'redis'

  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'rspec-rails', '~> 6.0', '>= 6.0.1'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rails'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'mock_redis'
  spec.add_development_dependency 'timecop'
end
