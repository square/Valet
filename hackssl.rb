require 'openssl'
puts " ==== hacking ssl ==="
OpenSSL::SSL.const_set :VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE
