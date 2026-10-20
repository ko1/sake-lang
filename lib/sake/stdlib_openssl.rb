# frozen_string_literal: true

module Sake
  module Stdlib
    module_function

    OPENSSL_CIPHER = "OpenSSL::Cipher"
    # Ruby's openssl exception classes, rescuable by these names; all are under OpenSSL::OpenSSLError.
    OPENSSL_EXCEPTIONS = %w[OpenSSL::OpenSSLError OpenSSL::Digest::DigestError OpenSSL::HMACError OpenSSL::KDF::KDFError
                            OpenSSL::Cipher::CipherError OpenSSL::Cipher::AuthTagError].freeze
    OPENSSL_EXCEPTION_PARENT = OPENSSL_EXCEPTIONS.drop(1).to_h { [_1, "OpenSSL::OpenSSLError"] }
                                                 .merge("OpenSSL::Cipher::AuthTagError" => "OpenSSL::Cipher::CipherError").freeze

    # OpenSSL::HMAC, OpenSSL::KDF / PKCS5 (PBKDF2), OpenSSL::Cipher and OpenSSL::Random over Ruby's openssl.
    # A digest is named by a String ("SHA256", any case); a Cipher is Ruby's OpenSSL::Cipher.
    def install_openssl(reg)
      %i[digest hexdigest base64digest].each do |m|
        reg.define("OpenSSL::HMAC", m, %w[String String String]) { |alg, key, data| openssl_error { ::OpenSSL::HMAC.public_send(m, alg, key, data) } }
      end
      reg.define("OpenSSL::KDF", :pbkdf2_hmac, ["String"], keywords: { "salt" => "String", "iterations" => "Integer", "length" => "Integer", "hash" => "String" }) do |pass, **kw|
        missing = %i[salt iterations length hash] - kw.keys
        raise Fail.new("ArgumentError", "missing keyword#{"s" if missing.size > 1}: #{missing.map(&:inspect).join(", ")}") unless missing.empty?
        openssl_error { ::OpenSSL::KDF.pbkdf2_hmac(pass, **kw) }
      end
      reg.define("OpenSSL::PKCS5", :pbkdf2_hmac, %w[String String Integer Integer String]) do |pass, salt, iter, len, alg|
        openssl_error { ::OpenSSL::PKCS5.pbkdf2_hmac(pass, salt, iter, len, alg) }
      end
      reg.define("OpenSSL::PKCS5", :pbkdf2_hmac_sha1, %w[String String Integer Integer]) do |pass, salt, iter, len|
        openssl_error { ::OpenSSL::PKCS5.pbkdf2_hmac(pass, salt, iter, len, "sha1") }
      end
      reg.define("OpenSSL::Random", :random_bytes, ["Integer"]) { |n| nonneg(n) && openssl_error { ::OpenSSL::Random.random_bytes(n) } }
      c = OPENSSL_CIPHER
      reg.define(c, :new, ["String"]) { |name| openssl_error { ::OpenSSL::Cipher.new(name) } }
      reg.define(c, :ciphers, []) { openssl_error { ::OpenSSL::Cipher.ciphers.map(&:dup) } }
      %i[encrypt decrypt].each { |m| reg.define(c, m, [c]) { |x| openssl_error { x.public_send(m) } } }
      # set_key(c, s) and the others: Ruby's c.key = s (the value given back, as an assignment's).
      %w[key iv auth_tag auth_data].each do |f|
        reg.define(c, :"set_#{f}", [c, "String"]) { |x, s| openssl_error { x.public_send(:"#{f}=", s) }.then { s } }
      end
      %w[padding iv_len].each do |f|
        reg.define(c, :"set_#{f}", [c, "Integer"]) { |x, n| openssl_error { x.public_send(:"#{f}=", n) }.then { n } }
      end
      reg.define(c, :auth_tag, [c], optional: ["Integer"]) { |x, n = 16| openssl_error { x.auth_tag(n) } }
      reg.define(c, :update, [c, "String"]) { |x, s| openssl_error { x.update(s) } }
      reg.define(c, :final, [c]) { |x| openssl_error { x.final } }
      %i[random_iv random_key reset].each { |m| reg.define(c, m, [c]) { |x| openssl_error { x.public_send(m) }.then { m == :reset ? x : _1 } } }
      reg.define(c, :name, [c]) { |x| x.name.dup }
      %i[key_len iv_len block_size authenticated?].each { |m| reg.define(c, m, [c], &m) }
    end

    def openssl_error
      require "openssl"
      yield
    rescue LoadError => e
      raise Fail.new("IOError", "openssl is not available here (#{e.message})")
    rescue ::StandardError => e
      raise unless defined?(::OpenSSL::OpenSSLError) && e.is_a?(::OpenSSL::OpenSSLError)
      name = e.class.ancestors.map(&:name).find { OPENSSL_EXCEPTIONS.include?(_1) }
      raise Fail.new(name || "OpenSSL::OpenSSLError", e.message)
    end
  end
end
