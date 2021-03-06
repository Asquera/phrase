require 'spec_helper'

describe Phrase::Tool::Options do
  describe "#get" do
    context "init command" do
      let(:command) { "init" }
      let(:args) { ["--secret=foobar", "--default-locale=hu", "--default-target=app/locales/", "--domain=app", "--locale-filename=<locale.name>.<format>", "--locale-directory=./<locale.name>/"] }
      
      describe "the secret" do
        subject { Phrase::Tool::Options.new(args, command).get(:secret) }
        
        it { should eql("foobar") }
      end
      
      describe "the default locale" do
        subject { Phrase::Tool::Options.new(args, command).get(:default_locale) }
        
        it { should eql("hu") }
      end

      describe "the default target" do
        subject { Phrase::Tool::Options.new(args, command).get(:target_directory) }

        it { should eql "app/locales/" }
      end

      describe "the domain" do
        subject { Phrase::Tool::Options.new(args, command).get(:domain) }

        it { should eql "app" }
      end
      
      describe "the locale directory" do
        subject { Phrase::Tool::Options.new(args, command).get(:locale_directory) }

        it { should eql "./<locale.name>/" }
      end
      
      describe "the locale filename" do
        subject { Phrase::Tool::Options.new(args, command).get(:locale_filename) }

        it { should eql "<locale.name>.<format>" }
      end
    end
    
    context "push command" do
      let(:command) { "push" }
      let(:args) { ["--tags=lorem,ipsum", "--recursive", "--locale=fr"] }
      
      describe "tags" do
        subject { Phrase::Tool::Options.new(args, command).get(:tags) }
        
        it { should eql(["lorem", "ipsum"]) }
      end
      
      describe "locale" do
        subject { Phrase::Tool::Options.new(args, command).get(:locale) }
        
        it { should == "fr" }
      end
      
      describe "recursive" do
        subject { Phrase::Tool::Options.new(args, command).get(:recursive) }
        
        it { should be_true }
      end
    end
    
    context "pull command" do
      let(:command) { "pull" }
      let(:args) { ["--format=po", "--target=/foo/bar"] }
      
      describe "format" do
        subject { Phrase::Tool::Options.new(args, command).get(:format) }
        
        it { should eql "po" }
      end
      
      describe "target" do
        subject { Phrase::Tool::Options.new(args, command).get(:target) }
        
        it { should eql "/foo/bar" }
      end
    end
    
    context "no command" do
      let(:command) { nil }
      let(:args) { ["-h", "-v"] }
      
      describe "help param" do
        subject { Phrase::Tool::Options.new(args, command).get(:help) }
        
        it { should be_true }
      end
      
      describe "version param" do
        subject { Phrase::Tool::Options.new(args, command).get(:version) }
        
        it { should be_true }
      end
    end
  end
  
  describe "#options" do
    subject { Phrase::Tool::Options.new([]).send(:options) }
    
    it { should be_a OptionParser }
  end
end
