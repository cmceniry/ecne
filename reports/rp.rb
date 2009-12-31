libs =  " -r irb/completion"
libs << " -r #{RAILS_ROOT}/config/environment"
libs << " -r console_app"
libs << " -r console_sandbox" if options[:sandbox]
libs << " -r console_with_helpers"

ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
#if options[:sandbox]
#  puts "Loading #{ENV['RAILS_ENV']} environment in sandbox."
#  puts "Any modifications you make will be rolled back on exit."
#else
#  puts "Loading #{ENV['RAILS_ENV']} environment."
#end
exec "#{options[:irb]} #{libs} --simple-prompt"
