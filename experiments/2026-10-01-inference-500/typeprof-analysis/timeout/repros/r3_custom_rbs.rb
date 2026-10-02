# Livelock with a user-declared method; see r3_custom_rbs.rbs. Run: typeprof r3_custom_rbs.rb r3_custom_rbs.rbs
# (no Ruby implementation needed; TypeProf only reads the signature)
x = yield_pair { |a, b| b }
