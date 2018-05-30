require "./librtlsdr/*"

@[Link("rtlsdr")]
lib LibRtlSdr
  alias RtlSdrDev = Void*

  enum Tuner
    UNKNOWN = 0,
    E4000,
    FC0012,
    FC0013,
    FC2580,
    R820T,
    R828D
  end

  fun rtlsdr_get_device_count : UInt32
  fun rtlsdr_get_device_name(index : UInt32) : UInt8*
  fun rtlsdr_get_device_usb_strings(index : UInt32,
                                    manufact : UInt8*,
                                    product : UInt8*,
                                    serial : UInt8*) : Int32
  fun rtlsdr_open(dev : RtlSdrDev*, index : UInt32) : Int32
  fun rtlsdr_close(dev : RtlSdrDev) : Int32
  fun rtlsdr_get_xtal_freq(dev : RtlSdrDev,
                           rtl_freq : UInt32*,
                           tuner_freq : UInt32*) : Int32
  fun rtlsdr_set_sample_rate(dev : RtlSdrDev, rate : UInt32) : Int32
  fun rtlsdr_get_sample_rate(dev : RtlSdrDev) : UInt32
  fun rtlsdr_get_index_by_serial(serial : UInt8*) : Int32
  fun rtlsdr_set_center_freq(dev : RtlSdrDev, freq : UInt32) : Int32
  fun rtlsdr_get_center_freq(dev : RtlSdrDev) : UInt32
  fun rtlsdr_set_freq_correction(dev : RtlSdrDev, ppm : Int32) : Int32
  fun rtlsdr_get_freq_correction(dev : RtlSdrDev) : Int32
  fun rtlsdr_get_tuner_type(dev : RtlSdrDev) : Tuner
  fun rtlsdr_get_tuner_gains(dev : RtlSdrDev, gains : Int32*) : Int32
  fun rtlsdr_set_tuner_gain(dev : RtlSdrDev, gain : Int32) : Int32
  fun rtlsdr_get_tuner_gain(dev : RtlSdrDev) : Int32
  fun rtlsdr_set_tuner_bandwidth(dev : RtlSdrDev, bw : UInt32) : Int32
  fun rtlsdr_get_tuner_bandwidth(dev : RtlSdrDev) : UInt32
  fun rtlsdr_set_tuner_if_gain(dev : RtlSdrDev, stage : Int32, gain : Int32) : Int32
  fun rtlsdr_set_tuner_gain_mode(dev : RtlSdrDev, manual : Int32) : Int32
  fun rtlsdr_set_testmode(dev : RtlSdrDev, on : Int32) : Int32
  fun rtlsdr_set_agc_mode(dev : RtlSdrDev, on : Int32) : Int32
  fun rtlsdr_set_direct_sampling(dev : RtlSdrDev, on : Int32) : Int32
  fun rtlsdr_get_direct_sampling(dev : RtlSdrDev) : Int32
  fun rtlsdr_set_offset_tuning(dev : RtlSdrDev, on : Int32) : Int32
  fun rtlsdr_get_offset_tuning(dev : RtlSdrDev) : Int32
  fun rtlsdr_reset_buffer(dev : RtlSdrDev) : Int32
  fun rtlsdr_read_sync(dev : RtlSdrDev,
                       buf : Void*,
                       len : Int32,
                       n_read : Int32*) : Int32
  fun rtlsdr_wait_async(dev : RtlSdrDev, cb : Void*, ctx : Void*) : Int32
  fun rtlsdr_read_async(dev : RtlSdrDev,
                        cb : Void*,
                        ctx : Void*,
                        buf_num : UInt32,
                        buf_len : UInt32) : Int32
  fun rtlsdr_cancel_async(dev : RtlSdrDev) : Int32
  fun rtlsdr_set_bias_tee(dev : RtlSdrDev, on : Int32) : Int32
end

class RtlSdr
  alias Device = LibRtlSdr::RtlSdrDev
  @device : Device = Device.new(0)

  def device_count : Int32
    LibRtlSdr.rtlsdr_get_device_count.to_i32
  end

  def device_name(index : Int32 = -1) : String
    index = device_count - 1 if index == -1
    name = LibRtlSdr.rtlsdr_get_device_name(index.to_u32)
    String.new(name)
  end

  def device_usb_strings(index : Int32 = -1)
    index = device_count - 1 if index == -1
    manufacturer = Bytes.new(256)
    product = Bytes.new(256)
    serial = Bytes.new(256)
    LibRtlSdr.rtlsdr_get_device_usb_strings(
      index.to_u32,
      manufacturer,
      product,
      serial)
    {"manufacturer" => String.new(manufacturer),
     "product"      => String.new(product),
     "serial"       => String.new(serial)}
  end

  def open(index : Int32 = -1)
    index = device_count - 1 if index == -1
    dev_ptr = pointerof(@device)
    res = LibRtlSdr.rtlsdr_open(dev_ptr, index.to_u32)
    raise "Error: name is NULL!" if res == -1
    raise "Error: no devices found!" if res == -2
    raise "Error: no matching device found!" if res == -3
    res
  end

  def close
    LibRtlSdr.rtlsdr_close(@device)
  end

  def xtal_frequency
    rtl_freq = 0_u32
    tuner_freq = 0_u32
    unless LibRtlSdr.rtlsdr_get_xtal_freq(
             @device,
             pointerof(rtl_freq),
             pointerof(tuner_freq))
      raise "Error: Failed to get frequency!"
    end
    {"rtl" => rtl_freq.to_i32, "tuner" => tuner_freq.to_i32}
  end

  def sample_rate=(rate)
    invalid_rate = true
    if (rate > 225000 && rate <= 300000) ||
       (rate > 900000 && rate <= 3200000)
      invalid_rate = false
    end
    raise "Error: Invalid rate in set rate attempt!" if invalid_rate
    ret = LibRtlSdr.rtlsdr_set_sample_rate(@device, rate.to_u32)
    raise "Error: Failed to set sample rate" unless ret == 0
  end

  def sample_rate : Int32
    LibRtlSdr.rtlsdr_get_sample_rate(@device).to_i32
  end

  def index_by_serial(serial : String) : Int32
    res = LibRtlSdr.rtlsdr_get_index_by_serial(serial.to_unsafe)
    raise "Error: name is NULL!" if res == -1
    raise "Error: no devices found!" if res == -2
    raise "Error: no device with matching name found!" if res == -3
    res
  end

  def center_freq=(freq : Int32)
    LibRtlSdr.rtlsdr_set_center_freq(@device, freq.to_u32)
  end

  def center_freq : Int32
    res = LibRtlSdr.rtlsdr_get_center_freq(@device).to_i32
    raise "Error: failed to get center frequency" if res == 0
    res
  end

  def frequency_correction=(ppm)
    res = LibRtlSdr.rtlsdr_set_freq_correction(@device, ppm)
    raise "Error: failed to set frequency correction!" unless res == 0
  end

  def frequency_correction
    LibRtlSdr.rtlsdr_get_freq_correction(@device)
  end

  def tuner_type
    LibRtlSdr.rtlsdr_get_tuner_type(@device).to_s
  end

  def tuner_gains : Array(Int32)
    gains = Slice.new(20, 0).to_unsafe
    count = LibRtlSdr.rtlsdr_get_tuner_gains(@device, gains)
    raise "Error: Failed to fetch tuner gains" if count == 0
    arr = Array(Int32).new(count)
    count.times do
      arr << gains.value
      gains += 1
    end
    arr
  end

  def tuner_gain=(gain : Int32)
    res = LibRtlSdr.rtlsdr_set_tuner_gain(@device, gain)
    raise "Error: failed to set tuner gain!" unless res == 0
  end

  def tuner_gain : Int32
    res = LibRtlSdr.rtlsdr_get_tuner_gain(@device)
    raise "Error: failed to fetch tuner gain" if res == 0
    res
  end

  def tuner_bandwidth=(bw : Int32)
    res = LibRtlSdr.rtlsdr_set_tuner_bandwidth(@device, bw.to_u32)
    raise "Error: failed to set tuner bandwidth" unless res == 0
    res
  end

  def set_tuner_if_gain(stage : Int32, gain : Int32) : Int32
    res = LibRtlSdr.rtlsdr_set_tuner_if_gain(@device, stage, gain)
    raise "Error: failed to set tuner i.f. gain" unless res == 0
    res
  end

  def tuner_gain_mode=(manual : Int32) : Int32
    res = LibRtlSdr.rtlsdr_set_tuner_gain_mode(@device, manual)
    raise "Error: failed to set tuner i.f. gain" unless res == 0
    res
  end

  def reset_buffer
    res = LibRtlSdr.rtlsdr_reset_buffer(@device)
    raise "Error: failed to reset buffer!" unless res == 0
  end

  def read_sync : Int32
    actual_count = 0
    100000.times do
      count = 1024
      buf = Slice(UInt8).new(1024)

      res = LibRtlSdr.rtlsdr_read_sync(@device,
                                       buf.to_unsafe,
                                       count,
                                       pointerof(actual_count))
      # puts "actual count = #{actual_count}\n\n"
      raise "Error! failed to read synchronously" unless res == 0
      STDOUT.puts buf.hexdump
      STDOUT.flush
    end
    actual_count
  end
end
#TODO
# func (c *Context) ReadSync(buf []uint8, len int) (n_read int, err int) {
# 	err = int(C.rtlsdr_read_sync((*C.rtlsdr_dev_t)(c.dev),
# 		unsafe.Pointer(&buf[0]),
# 		C.int(len),
# 		(*C.int)(unsafe.Pointer(&n_read))))
# 	return
# }
