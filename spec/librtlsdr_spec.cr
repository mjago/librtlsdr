require "./spec_helper"

describe RtlSdr do
  it "instantiates RtlSdr" do
    sdr = RtlSdr.new
    sdr.class.should eq(RtlSdr)
    sdr.close
  end

  it "counts devices" do
    sdr = RtlSdr.new
    count = sdr.device_count
    (count > 0).should be_true
    sdr.close
  end

  it "returns device usb strings" do
    sdr = RtlSdr.new
    data = sdr.device_usb_strings(0)
    data.class.should eq(Hash(String, String))
    data["manufacturer"].size.should_not eq(0)
    data["product"].size.should_not eq(0)
    data["serial"].size.should_not eq(0)
    sdr.close
  end

  it "reads xtal frequency" do
    sdr = RtlSdr.new
    sdr.open
    freqs = sdr.xtal_frequency
    (freqs["rtl"] > 0).should be_true
    (freqs["tuner"] > 0).should be_true
    sdr.close
  end

  it "sets and reads sample rate" do
    sdr = RtlSdr.new
    sdr.open
    sdr.sample_rate = 2.4e6
    rate = sdr.sample_rate
    rate.should eq(2.4e6)
    sdr.close
  end

  it "raises for invalid sample rates" do
    sdr = RtlSdr.new
    sdr.open
    expect_raises(Exception, "Error: Invalid rate in set rate attempt!") do
      sdr.sample_rate = 22500
    end
    sdr.close
  end

  it "gets index by serial" do
    sdr = RtlSdr.new
    data = sdr.device_usb_strings(0)
    serial = data["serial"] # .as(UInt8*)
    index = sdr.index_by_serial(serial)
    index.should eq(0)
    sdr.close
  end

  it "sets and gets center frequency" do
    sdr = RtlSdr.new
    sdr.open
    sdr.center_freq = 1024
    sdr.center_freq.should eq(1024)
    sdr.close
  end

  it "sets and gets frequency correction" do
    sdr = RtlSdr.new
    sdr.open
    sdr.frequency_correction = 29
    sdr.frequency_correction.should eq(29)
    sdr.close
  end

  it "fetches enumerated tuner type" do
    sdr = RtlSdr.new
    sdr.open
    sdr.tuner_type.class.should eq(String)
    sdr.close
  end

  it "fetches tuner gains" do
    sdr = RtlSdr.new
    sdr.open
    gains = sdr.tuner_gains
    gains.class.should eq(Array(Int32))
    (gains.size > 1).should be_true
    sdr.close
  end

  it "sets and gets tuner gain" do
    sdr = RtlSdr.new
    sdr.open
    gains = sdr.tuner_gains
    sdr.tuner_gain = gains[0]
    sdr.tuner_gain.should eq(gains[0])
    sdr.tuner_gain = gains[-1]
    sdr.tuner_gain.should eq(gains[-1])
    sdr.tuner_gain = 0 # automatic gain selection
    sdr.close
  end

  it "sets tuner bandwidth" do
    sdr = RtlSdr.new
    sdr.open
    sdr.tuner_bandwidth = 10000
    sdr.tuner_bandwidth = 0 # automatic bw selection
    sdr.close
  end

  it "sets tuner if gain" do
    sdr = RtlSdr.new
    sdr.open
    sdr.set_tuner_if_gain(stage: 5, gain: 30)
    sdr.close
  end

  it "sets tuner gain mode" do
    sdr = RtlSdr.new
    sdr.open
    sdr.tuner_gain_mode = 0
    sdr.close
  end
end
