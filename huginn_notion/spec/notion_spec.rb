require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::Notion do
  before(:each) do
    @valid_options = Agents::Notion.new.default_options
    @checker = Agents::Notion.new(:name => "Notion", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
