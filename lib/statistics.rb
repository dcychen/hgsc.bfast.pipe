#!/usr/bin/env ruby19
#
# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80

module Statistics
  GB = 1000000000
  TB = 1000000000000

  def self.to_gb(num)
    num/GB
  end

  def self.to_tb(num)
    num/TB
  end
  # compute and ouputs the sum
  def self.sum(values)
    total = 0
    values.each { |x| total = total + x}
    total
  end

  # compute and output the mean from the values
  def self.mean(values)
    sum = sum(values)
    mean = 0.0
    if values.size == 0
      return 0
    else
      mean = mean + sum / values.size
    end
  end

  def self.variance(samples)
    mean = mean(samples)
    total = 0.0
    samples.each do |x|
      total = total + (x - mean)*(x - mean)
    end
    if samples.size == 1
      return total
    elsif samples.size == 0
      return 0
    else
      return total / (samples.size - 1)
    end
  end

  def self.std_dev(samples)
    round_to_two_dig(Math.sqrt(variance(samples)))
  end

  def self.round_to_two_dig(num)
    ('%.2f' % num).to_f
  end
  
  # return array of mean and sd 
  def self.mean_sd(samples)
    m  = mean(samples)
    sd = std_dev(samples)
    [m, sd]
  end
end 
