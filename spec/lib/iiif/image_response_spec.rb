require 'spec_helper.rb'

describe IIIF::ImageResponse do
  subject do
    described_class.new(id:       id,
                        region:   region,
                        size:     size,
                        rotation: rotation,
                        quality:  quality,
                        format:   format)
  end

  let(:id) { 'moomin' }
  let(:region) { 'full' }
  let(:size) { 'full' }
  let(:rotation) { '0' }
  let(:quality) { 'default' }
  let(:format) { 'jpg' }
end

shared_examples 'a parameter' do
  subject { described_class.new(valids.first, *args) }

  it 'has a canonical value' do
    expect(subject.canonical_value).to be_a String
  end
  
  it 'validates for valid values' do
    valids.each do |valid|
      expect(described_class.new(valid, *args)).to be_valid
    end
  end

  it 'invalidates for invalid values' do
    invalids.each do |invalid|
      expect(described_class.new(invalid, *args)).not_to be_valid
    end
  end

  describe '#validate!' do
  end
end

describe IIIF::ImageResponse::Parameter

describe IIIF::ImageResponse::Region do
  it_behaves_like 'a parameter' do
    let(:args) { [100, 100] }
    let(:valids) do
      ['1,2,3,4', 'pct:1,2,3,4', 'full', 'pct:0,0,100,100']
    end

    let(:invalids) do
      ['not_valid', 'pct:a,b,c,d', 'ful', 'a,b,c,d', '', '1,2,3'] 
    end
  end

  subject { described_class.new('1,2,3,4', 100, 100) }
  
  describe '#valid?' do
    it 'is not valid with silly percentages' do
      expect(described_class.new('pct:100,100,100,100', 101, 101))
        .not_to be_valid
    end

    it 'is not valid with oversized start point' do
      expect(described_class.new('110,110,100,100', 101, 101)).not_to be_valid
    end

    it 'is not valid with oversized start point percentage' do
      q = 'pct:105,105,100,100'
      expect(described_class.new(q, 101, 101)).not_to be_valid
    end
  end

  describe '#canonical' do
    it 'keep full when full' do
      expect(described_class.new('full').canonical_value).to eq 'full'
    end

    it 'x,y,w,h are formatted' do
      expect(subject.canonical_value).to eq '1,2,3,4'
    end

    it 'x,y,w,h are formatted with math(s)' do
      expect(described_class.new('100,100,100,100', 101, 101).canonical_value)
        .to eq '100,100,1,1'
    end

    it 'x,y,w,h are formatted when start point is overlarge' do
      expect(described_class.new('110,110,100,100', 101, 101).canonical_value)
        .to eq '110,110,0,0'
    end

    it 'x,y,w,h are formatted with percentage' do
      q = 'pct:50,50,100,100'
      expect(described_class.new(q, 101, 101).canonical_value)
        .to eq '50,50,51,51'
    end

    it 'x,y,w,h are formatted when percentage is 100 ' do
      q = 'pct:100,100,100,100'
      expect(described_class.new(q, 101, 101).canonical_value)
        .to eq '101,101,0,0'
    end

    it 'x,y,w,h are formatted when percentage is greater than 100' do
      q = 'pct:105,105,100,100'
      expect(described_class.new(q, 101, 101).canonical_value)
        .to eq '106,106,0,0'
    end
  end
  
  describe '#full?' do
    it 'is full when full' do
      expect(described_class.new('full')).to be_full
    end

    it 'is full when 0,0,max_w,max_h' do
      expect(described_class.new('0,0,100,100', 1, 1)).to be_full
    end
    
    it 'is full when pct:0,0,100,100' do
      expect(described_class.new('pct:0,0,100,100', 1, 1)).to be_full
    end

    it 'is full when super-full' do
      expect(described_class.new('pct:0,0,101,101', 1, 1)).to be_full
    end

    it 'is not full when not full' do
      expect(subject).not_to be_full
    end
  end

  describe '#pct?' do
    it 'is pct when pct' do
      expect(described_class.new('pct:0,0,10,10', 1, 1)).to be_pct
    end

    it 'is not pct when not pct' do
      expect(described_class.new('0,0,10,10', 1, 1)).not_to be_pct
    end

    it 'is not pct when full' do
      expect(described_class.new('pct:0,0,100,100', 1, 1)).not_to be_pct
    end

    it 'is not pct when super-full' do
      expect(described_class.new('pct:0,0,101,101', 1, 1)).not_to be_pct
    end
  end
end

describe IIIF::ImageResponse::Rotation do
  it_behaves_like 'a parameter' do
    let(:args) { [] }
    let(:valids) { ['0', '!0', '!180', '!180', '360', '!360', '0.1', '!0.1'] }
    let(:invalids) { ['361', '!361', '360.1', '!360.1', '-1', '!-1', 'a39'] }
  end

  subject { described_class.new('90') }

  describe '#canonical_value' do
    it 'gives int version if no decimal values' do
      expect(subject.canonical_value).to eq '90'
    end

    it 'gives int version if decimal values is .0' do
      expect(described_class.new('90.0').canonical_value).to eq '90'
    end

    it 'gives float version if decimal values are present' do
      expect(described_class.new('90.1').canonical_value).to eq '90.1'
    end

    it 'gives mirror character if decimal values are present' do
      expect(described_class.new('!90.1').canonical_value).to eq '!90.1'
    end

    it 'has a system precision float cap' do
      value = '90.1111111111111111111111111111'
      expect(described_class.new(value).canonical_value).to eq value.to_f.to_s
    end
  end

  describe '#in_range?' do
    it 'is in range for values between 0 and 360' do
      ['0', '0.1', '90', '360'].each do |val|
        expect(described_class.new(val)).to be_in_range
      end
    end

    it 'is out of range for other values' do
      ['-1', '-0.1', '900', '360.1'].each do |val|
        expect(described_class.new(val)).not_to be_in_range
      end
    end
  end

  describe '#rotation' do
    it 'gives nil when no match' do
      expect(described_class.new('moomin').rotation).to be_nil
    end

    it 'gives rotation as float with match' do
      expect(described_class.new('360').rotation).to eql 360.0
    end

    it 'gives rotation as float with mirrored match' do
      expect(described_class.new('!360').rotation).to eql 360.0
    end
  end

  describe '#mirror?' do
    it 'gives false when no match' do
      expect(described_class.new('moomin')).not_to be_mirror
    end

    it 'gives false when mirror char is not present' do
      expect(described_class.new('360')).not_to be_mirror
    end

    it 'gives true when mirror char is present' do
      expect(described_class.new('!360')).to be_mirror
    end
  end
end
