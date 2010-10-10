require File.join(File.dirname(__FILE__), 'parallel_testbot')

class ParallelTestbotCucumber < ParallelTestbot
  
  def self.run_tests(test_files, process_number)
    run_tests_with_type(test_files, process_number, 'cucumber')
  end
    
  protected

  # TODO: Spec
  def self.test_result_seperator
    ' '
  end

  # TODO: Spec
  def self.line_is_result?(line)
    line =~ /^\d+ steps/
  end
  
  # TODO: Spec
  def self.line_is_failure?(line)
    line =~ /^\d+ steps.*(\d{2,}|[1-9]) failed/
  end

  def self.find_tests(root)
    Dir["#{root}**/**/*.feature"]
  end

end
