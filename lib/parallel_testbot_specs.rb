require File.join(File.dirname(__FILE__), 'parallel_testbot')

class ParallelTestbotSpecs < ParallelTestbot
  
  def self.run_tests(test_files, process_number)
    run_tests_with_type(test_files, process_number, 'rspec')
  end
    
  protected

  def self.find_tests(root)
    Dir["#{root}**/**/*_spec.rb"]
  end
  
end
