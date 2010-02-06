require File.dirname(__FILE__) + '/spec_helper'

describe ParallelTestbotspecs do

  describe :run_tests do

    before :each do
      # Stubbing config on ParallelTestbotspecs because I want caching and that won't work in the tests.
      ParallelTestbotspecs.stub!(:config).
                             and_return(OpenStruct.new({ "server_path" => "server:/tmp/testbot/:user" }))
      ParallelTestbotspecs.stub!(:sleep)
      ParallelTestbotspecs.stub!(:puts)
    end
    
    it "should send a request and get the result" do      
      TestbotServer.should_receive(:post).with('/jobs',
                  :body => { :root => "server:/tmp/testbot/:user",
                             :files => 'xxx yyy' }).and_return(5)
      TestbotServer.should_receive(:get).with('/jobs/5').and_return('test-results')
      ParallelTestbotspecs.should_receive(:puts).with('test-results')
      ParallelTestbotspecs.run_tests([ 'xxx', 'yyy' ], 1).should == 'test-results'
    end
    
    it "should not return until a result has been given" do
      TestbotServer.stub!(:post).and_return(10)
      TestbotServer.should_receive(:get).with('/jobs/10').twice.and_return(nil, 'results')
      ParallelTestbotspecs.should_receive(:puts).with('results')
      ParallelTestbotspecs.run_tests([ 'aaa', 'bbb' ], 1)
    end
    
    it "should sleep between checks" do
      TestbotServer.stub!(:post).and_return(10)
      TestbotServer.stub!(:get).with('/jobs/10').twice.and_return(nil, nil, 'results')
      ParallelTestbotspecs.should_receive(:sleep).with(1).twice
      ParallelTestbotspecs.run_tests([ 'aaa', 'bbb' ], 1)
    end
    
    it "should make all file paths relative" do
      TestbotServer.should_receive(:post).with('/jobs',
                  :body => { :root => "server:/tmp/testbot/:user",
                             :files => 'spec/models/car_spec.rb' }).and_return(10)      
      TestbotServer.stub!(:post).and_return(10)
      TestbotServer.stub!(:get).and_return('results')
      ParallelTestbotspecs.run_tests([ "#{FileUtils.pwd}/spec/models/car_spec.rb" ], 1)      
    end
  
  end
  
  describe :prepare do
    
    it "should rsync files to the server and setup httparty" do
      TestbotServer.should_receive(:base_uri).with("http://testbotserver:5555")
      ParallelTestbotspecs.stub!(:config).
                             and_return(OpenStruct.new({ "server_path" => "server:/tmp/testbot/:user",
                                                         "ignores"     => "log/* tmp/*",
                                                         "server_uri"  => "http://testbotserver:5555" }))
      ParallelTestbotspecs.should_receive(:system).with("rake testbot:before_request &> /dev/null; rsync -az --delete -e ssh --exclude='log/*' --exclude='tmp/*' . server:/tmp/testbot/#{ENV['USER']}")
      ParallelTestbotspecs.prepare
    end
    
  end
  
  describe :process_count do
    
    it "should query the server for the number of available_instances return it" do
      TestbotServer.should_receive(:base_uri).with("http://testbotserver:5555")
      ParallelTestbotspecs.stub!(:config).
                             and_return(OpenStruct.new({ "server_uri"  => "http://testbotserver:5555" }))
      TestbotServer.should_receive(:get).with('/runners/available_instances').and_return('10')
      ParallelTestbotspecs.process_count.should == 10
    end
    
  end
  
end
