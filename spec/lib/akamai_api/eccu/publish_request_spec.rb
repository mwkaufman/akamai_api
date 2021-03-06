require 'spec_helper'

describe AkamaiApi::ECCU::PublishRequest do
  subject { AkamaiApi::ECCU::PublishRequest.new 'foo.com', type: 'hostasd', exact_match: 'foo' }

  describe 'constructor' do
    it 'sets property_name to the given value' do
      expect(subject.property_name).to eq 'foo.com'
    end

    it 'sets property_type to the given value' do
      expect(subject.property_type).to eq 'hostasd'
    end

    it 'sets property_type to hostheader if no value is given' do
      subject = AkamaiApi::ECCU::PublishRequest.new 'foo.com'
      expect(subject.property_type).to eq 'hostheader'
    end

    it 'sets property_exact_match to the given boolean value' do
      expect(subject.property_exact_match).to be_false
    end

    it 'sets property_exact_match to true if no value is given' do
      subject = AkamaiApi::ECCU::PublishRequest.new 'foo.com'
      expect(subject.property_exact_match).to be_true
    end
  end

  describe '#execute' do
    let(:fake_client) { double call: nil }

    before do
      AkamaiApi::ECCU.stub client: fake_client
    end

    it "calls 'upload' via savon with a message and the message_tag 'upload'" do
      fake_response = double body: { upload_response: { file_id: 1 } }
      expect(subject).to receive(:request_body).with('foo', {}).and_return double(to_s: 'asd')
      expect(fake_client).to receive(:call).with(:upload, message_tag: 'upload', message: 'asd').and_return fake_response
      subject.execute 'foo'
    end

    it "returns the request Id" do
      subject.stub request_body: 'example'
      fake_client.stub call: double(body: { upload_response: { file_id: 1 } })
      expect(subject.execute 'foo').to be_a Fixnum
    end

    it "raises unauthorized if request raises a Savon::HTTPError with code 401" do
      expect(fake_client).to receive :call do
        raise Savon::HTTPError, double(code: 401)
      end
      expect { subject.execute 'foo' }.to raise_error AkamaiApi::Unauthorized
    end

    it "raises Savon:HTTPError if request raises this exception and its code differs from 401" do
      expect(fake_client).to receive :call do
        raise Savon::HTTPError, double(code: 402)
      end
      expect { subject.execute 'foo' }.to raise_error Savon::HTTPError
    end

    it "raises InvalidDomain if request raises a Savon::SOAPFault with particular message" do
      expect(fake_client).to receive :call do
        exc = Savon::SOAPFault.new({}, {})
        exc.stub to_hash: { fault: { faultstring: 'asdasd You are not authorized to specify this digital property.' } }
        exc.stub to_s: ''
        raise exc
      end
      expect { subject.execute 'foo' }.to raise_error AkamaiApi::ECCU::InvalidDomain
    end
  end

  describe '#subject_request_body' do
    def subject_request_body *args
      subject.send :request_body, *args
    end

    it 'sets a string with the given file name' do
      expect(subject_request_body('foo', file_name: 'asd').to_s).to include "<filename xsi:type=\"xsd:string\">asd</filename>"
    end

    it 'sets an empty string if no file name is found' do
      expect(subject_request_body('foo', {}).to_s).to include "<filename xsi:type=\"xsd:string\"></filename>"
    end

    it 'sets a text with the given content' do
      expect_any_instance_of(AkamaiApi::ECCU::SoapBody).to receive(:text).with :contents, 'asd'
      subject_request_body 'asd', {}
    end

    it 'sets a string with the given version' do
      expect(subject_request_body('asd', version: '1').to_s).to include "<versionString xsi:type=\"xsd:string\">1</versionString>"
    end

    it 'sets an empty string with there is no given version' do
      expect(subject_request_body('asd', {}).to_s).to include "<versionString xsi:type=\"xsd:string\"></versionString>"
    end

    it 'sets a string with the given notes' do
      expect(subject_request_body('asd', notes: 'asdasd').to_s).to include "<notes xsi:type=\"xsd:string\">asdasd</notes>"
    end

    it 'sets a string with a default message if no notes are given' do
      expect(subject_request_body('asd', {}).to_s).to include "<notes xsi:type=\"xsd:string\">ECCU Request using AkamaiApi #{AkamaiApi::VERSION}</notes>"
    end

    it 'sets a string with the given email' do
      expect(subject_request_body('asd', emails: 'foo@bar.com').to_s).to include "<statusChangeEmail xsi:type=\"xsd:string\">foo@bar.com</statusChangeEmail>"
    end

    it 'sets a string with the given emails' do
      expect(subject_request_body('asd', emails: ['foo@bar.com', 'asd@bar.com']).to_s).to include "<statusChangeEmail xsi:type=\"xsd:string\">foo@bar.com,asd@bar.com</statusChangeEmail>"
    end

    it 'sets no string with emails if no email is given' do
      expect(subject_request_body('asd', {}).to_s).to_not include "emails"
    end

    it 'sets the property name' do
      expect(subject_request_body('asd', {}).to_s).to include "<propertyName xsi:type=\"xsd:string\">foo.com</propertyName>"
    end

    it 'sets the property type' do
      expect(subject_request_body('asd', {}).to_s).to include "<propertyType xsi:type=\"xsd:string\">hostasd</propertyType>"
    end

    it 'sets the exact match' do
      expect(subject_request_body('asd', {}).to_s).to include "<propertyNameExactMatch xsi:type=\"xsd:boolean\">false</propertyNameExactMatch>"
    end
  end
end
