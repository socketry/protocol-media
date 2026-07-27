# frozen_string_literal: true

require "protocol/media/type"

describe Protocol::Media::Type do
	let(:type) {subject.parse("text/plain", extensions: ["txt"], encoding: "quoted-printable")}
	
	it "parses a media type" do
		expect(type.type).to be == "text"
		expect(type.subtype).to be == "plain"
		expect(type.name).to be == "text/plain"
		expect(type.extensions).to be == ["txt"]
		expect(type.encoding).to be == "quoted-printable"
	end
	
	it "converts to a string" do
		expect(type.to_s).to be == "text/plain"
	end
	
	it "rejects invalid names" do
		expect do
			subject.parse("text")
		end.to raise_exception(ArgumentError)
		
		expect do
			subject.parse("text/plain/extra")
		end.to raise_exception(ArgumentError)
	end
	
	it "normalizes names" do
		expect(subject.parse("TEXT/PLAIN").name).to be == "text/plain"
	end
	
	it "compares equivalent values" do
		other = subject.parse("text/plain")
		
		expect(type).to be == other
		expect(type.hash).to be == other.hash
	end
end
