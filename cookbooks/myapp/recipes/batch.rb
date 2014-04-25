require 'chef_metal_fog'

with_fog_ec2_driver

with_machine_batch 'the_new_batch'

1.upto(3) do |i|
  machine "cookie#{i}" do
    tag 'chocolate_chip'
  end
end
