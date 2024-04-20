require 'base64'

require_relative '../../../models/security/credentials'
require_relative '../../../models/security/encryption'

describe Encryption do
  let(:iv_base) { 'mzd7tC78EJfqpTh7dZTGEA==' }
  let(:salt_base) { 'FDEoedw639IGpO12JscieA==' }
  let(:unencrypted_value) { 'This is a test.' }
  let(:encrypted_value_base) { "J/5HzPLeFICPgyHtUvZHNg==\n" } # Base64
  let(:encrypted_value_hex) { Base64.decode64(encrypted_value_base) }

  let(:credentials) do
    Credentials.new('test', Base64.decode64(iv_base), Base64.decode64(salt_base))
  end

  subject { described_class.new }

  describe 'initialization' do
    subject { described_class }

    it 'creates a cipher' do
      expect(OpenSSL::Cipher).to receive(:new).with('AES-256-CBC')
      subject.new
    end
  end

  context 'when calling to encrypt or decrypt' do
    before { allow(subject).to receive(:credentials).and_return(credentials) }

    describe '#encrypt' do
      before { allow(Credentials).to receive(:acquire_password).and_return(credentials) }

      it 'calls encryption cipher setup' do
        expect(subject).to receive(:finish).with(unencrypted_value).and_call_original
        expect(subject).to receive(:final_value)

        subject.encrypt(unencrypted_value)
      end

      it 'encrypts data' do
        encrypted_data = subject.encrypt(unencrypted_value)[:value]
        expect(encrypted_data).to eq(encrypted_value_hex)
      end
    end

    describe '#decrypt' do
      before { allow(Credentials).to receive(:acquire_all).and_return(credentials) }

      it 'calls decrypt cipher setup' do
        expect(subject).to receive(:finish).with(encrypted_value_hex).and_call_original
        expect(subject).to receive(:final_value)

        subject.decrypt(encrypted_value_hex)
      end

      it 'decrypts data' do
        decrypted_data = subject.decrypt(encrypted_value_hex)[:value]
        expect(decrypted_data).to eq(unencrypted_value)
      end
    end
  end
end
