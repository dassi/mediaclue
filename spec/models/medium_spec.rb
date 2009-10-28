require File.dirname(__FILE__) + '/../spec_helper'

describe Medium do
  before(:each) do
    @medium = Medium.new
    # @medium.stub!(:temp_path).and_return('/tmp/blablabla.txt')
  end

  it "should be valid with a name" do
    @medium.name = 'test_medium'
    @medium.should be_valid
  end

  it "should not be valid without a name" do
    @medium.should_not be_valid
  end
  
  it 'should do importing meta data if option is_importing_metadata is set' do
    exiftool_mock = mock(MiniExiftool)
    exiftool_mock.should_receive(:to_yaml).and_return('xyz: blabla')
    MiniExiftool.should_receive(:new).and_return(exiftool_mock)

    @medium.should_receive(:need_to_save_attachment?).and_return(true)
    # @medium.stub!(:valid?).and_return(true)
    @medium.stub!(:set_size_from_temp_path).and_return(true)
    @medium.stub!(:filename).and_return('blabla.jpg')
    @medium.should_receive(:save_to_storage).and_return(true)
    
    @medium.is_importing_metadata = true
    @medium.should_receive(:meta_data=)

    @medium.name = 'test_medium'
    @medium.save!
  end

  it 'should not import meta data if option is_importing_metadata is not set' do
    MiniExiftool.should_not_receive(:new)
    
    @medium.is_importing_metadata = false
    @medium.should_not_receive(:meta_data=)
    
    @medium.stub!(:valid?).and_return(true)
    @medium.save!
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

    Medium.parse_tags("\"  bling   bling \" \" blang  blang \"").should eql(["bling bling", "blang blang"])

    Medium.parse_tags("\"bling bling\"  between  \"blang blang\"").should eql(["bling bling", "between", "blang blang"])

  end

  it "should allow special characters" do
    Medium.parse_tags("fünf, Ümit, schön, Öl, gesäß, Äste, voilà, liberté, ça").should eql(["fünf", "Ümit", "schön", "Öl", "gesäß", "Äste", "voilà", "liberté", "ça"])
  end

  # it "should downcase special characters correctly" do
  #   Medium.parse_tags("Ümit, Öl, Äste, \"À propos\", Ètat, Égalité").should eql(["ümit", "öl", "äste", "à propos", "ètat", "égalité"])
  # end
  
end
