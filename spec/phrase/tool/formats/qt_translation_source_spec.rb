require 'spec_helper'

describe Phrase::Tool::Formats::QtTranslationSource do
  let(:the_current_directory) { "./" }
  let(:the_prefix) { "phrase" }
  let(:the_locale) { "fooish" }
  let(:the_extension) { ".ts" }
  
  describe "#self.directory_for_locale" do
    it "should return the path to the current dir" do
      Phrase::Tool::Formats::QtTranslationSource.directory_for_locale(the_locale).should eql(the_current_directory)
    end
  end
  
  describe "#self.filename_for_locale" do
    subject { Phrase::Tool::Formats::QtTranslationSource.filename_for_locale(the_locale) }
    
    it { should include the_prefix }
    it { should include the_locale }
    it { should end_with the_extension }
  end
end