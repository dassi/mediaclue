require File.dirname(__FILE__) + '/../spec_helper'

describe Medium do
  before(:each) do
    @medium = Medium.new
  end

  it "should be valid with a name" do
    @medium.name = 'test_medium'
    @medium.should be_valid
  end

  it "should not be valid without a name" do
    @medium.should_not be_valid
  end

end

describe Medium, "and parsing tag strings" do

  it "should parse comma separated strings" do
    Medium.parse_tags("eins,zwei").should   eql(["eins", "zwei"])
    Medium.parse_tags("eins ,zwei").should  eql(["eins", "zwei"])
    Medium.parse_tags("eins  ,zwei").should eql(["eins", "zwei"])
    Medium.parse_tags("eins, zwei").should  eql(["eins", "zwei"])
    Medium.parse_tags("eins,  zwei").should eql(["eins", "zwei"])
    Medium.parse_tags("eins , zwei").should eql(["eins", "zwei"])
    Medium.parse_tags("eins  ,  zwei").should eql(["eins", "zwei"])
  end
  
  it "should parse semicolon separated strings" do
    Medium.parse_tags("eins;zwei").should   eql(["eins", "zwei"])
    Medium.parse_tags("eins ;zwei").should  eql(["eins", "zwei"])
    Medium.parse_tags("eins  ;zwei").should eql(["eins", "zwei"])
    Medium.parse_tags("eins; zwei").should  eql(["eins", "zwei"])
    Medium.parse_tags("eins;  zwei").should eql(["eins", "zwei"])
    Medium.parse_tags("eins ; zwei").should eql(["eins", "zwei"])
    Medium.parse_tags("eins  ;  zwei").should eql(["eins", "zwei"])
  end
  
  it "should parse blank separated strings" do
    Medium.parse_tags("eins zwei  drei  vier     funf").should eql(["eins", "zwei", "drei", "vier", "funf"])
  end

  it "should parse quoted strings as one tag" do
    Medium.parse_tags("\"bling bling\" \"blang blang\"").should eql(["bling bling", "blang blang"])
    Medium.parse_tags("\"bling,bling\" \"blang, blang\"").should eql(["bling,bling", "blang, blang"])
    Medium.parse_tags("\"bling;bling\" \"blang; blang\"").should eql(["bling;bling", "blang; blang"])
  end

  it "should allow special characters" do
    Medium.parse_tags("fünf, Ümit, schön, Öl, gesäß, Äste, voilà, liberté, ça").should eql(["fünf", "Ümit", "schön", "Öl", "gesäß", "Äste", "voilà", "liberté", "ça"])
  end

  # it "should downcase special characters correctly" do
  #   Medium.parse_tags("Ümit, Öl, Äste, \"À propos\", Ètat, Égalité").should eql(["ümit", "öl", "äste", "à propos", "ètat", "égalité"])
  # end
  
end
