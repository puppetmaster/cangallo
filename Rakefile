
begin
	require 'rspec/core/rake_task'
	RSpec::Core::RakeTask.new(:spec) do |t|
        t.pattern = Dir.glob("spec/**/*_spec.rc")
        t.rspec_opts = "--format documentation --color"
        #t.rcov = true
    end

	task :default => :spec
rescue LoadError
	STDERR.puts "rspec not found"
end



