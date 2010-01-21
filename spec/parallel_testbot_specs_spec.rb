require File.dirname(__FILE__) + '/spec_helper'

describe ParallelTestbotSpecs do

  describe :run_tests do

    before :each do
      # Stubbing config on ParallelTestbotSpecs because I want caching and that won't work in the tests.
      ParallelTestbotSpecs.stub!(:config).
                             and_return(OpenStruct.new({ "server_path" => "server:/tmp/testbot/:user",
                                                         "server_uri"  => "http://testbotserver:5555" }))
      ParallelTestbotSpecs.stub!(:sleep)
      TestbotServer.should_receive(:base_uri).with("http://testbotserver:5555")
    end
    
    it "should send a request and get the result" do      
      TestbotServer.should_receive(:post).with('/jobs',
                  :body => { :root => "server:/tmp/testbot/:user",
                             :files => 'xxx yyy' }).and_return(5)
      TestbotServer.should_receive(:get).with('/jobs/5').and_return('test-results')
      ParallelTestbotSpecs.run_tests([ 'xxx', 'yyy' ], 1).should == 'test-results'
    end
    
    it "should not return until a result has been given" do
      TestbotServer.stub!(:post).and_return(10)
      TestbotServer.should_receive(:get).with('/jobs/10').twice.and_return(nil, 'results')
      ParallelTestbotSpecs.run_tests([ 'aaa', 'bbb' ], 1).should == 'results'
    end
    
    it "should sleep between checks" do
      TestbotServer.stub!(:post).and_return(10)
      TestbotServer.stub!(:get).with('/jobs/10').twice.and_return(nil, nil, 'results')
      ParallelTestbotSpecs.should_receive(:sleep).with(1).twice
      ParallelTestbotSpecs.run_tests([ 'aaa', 'bbb' ], 1)
    end
  
  end
  
  describe :prepare do
    
    it "should rsync files to the server excluding files as specified" do
      ParallelTestbotSpecs.stub!(:config).
                             and_return(OpenStruct.new({ "server_path" => "server:/tmp/testbot/:user",
                                                         "ignores"     => "log/* tmp/*" }))
      ParallelTestbotSpecs.should_receive(:system).with("rsync -az --delete -e ssh --exclude='log/*' --exclude='tmp/*' . server:/tmp/testbot/#{ENV['USER']}")
      ParallelTestbotSpecs.prepare
    end
    
  end
  
end
