# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/media/type"

describe Protocol::Media::Type do
	let(:type) {subject.parse('text/plain; charset=utf-8; title="Plain Text"')}
	
	it "parses a media type" do
		expect(type.type).to be == "text"
		expect(type.subtype).to be == "plain"
		expect(type.name).to be == "text/plain"
		expect(type.parameters).to be == {"charset" => "utf-8", "title" => "Plain Text"}
	end
	
	it "converts to a string" do
		expect(type.to_s).to be == 'text/plain; charset=utf-8; title="Plain Text"'
	end
	
	it "parses quoted parameter values" do
		type = subject.parse('text/plain; note="a,b; c\\"d"; delimiter=","')
		
		expect(type.parameters).to be == {"note" => 'a,b; c"d', "delimiter" => ","}
		expect(type.to_s).to be == 'text/plain; note="a,b; c\\"d"; delimiter=","'
	end
	
	it "rejects invalid names" do
		expect do
			subject.parse("text")
		end.to raise_exception(ArgumentError)
		
		expect do
			subject.parse("text/*")
		end.to raise_exception(ArgumentError)
		
		expect do
			subject.parse("*/*")
		end.to raise_exception(ArgumentError)
		
		expect do
			subject.parse("text/plain/extra")
		end.to raise_exception(ArgumentError)
		
		expect do
			subject.parse("text/plain; invalid")
		end.to raise_exception(ArgumentError)
	end
	
	it "normalizes names" do
		expect(subject.parse("TEXT/PLAIN").name).to be == "text/plain"
		expect(subject.for("TEXT/PLAIN").name).to be == "text/plain"
	end
	
	it "normalizes compatible media type objects" do
		parameters = {"charset" => "utf-8"}
		compatible = Struct.new(:type, :subtype, :parameters).new("TEXT", "PLAIN", parameters)
		media_type = subject.for(compatible)
		
		expect(media_type).to be_a(subject)
		expect(media_type.name).to be == "text/plain"
		expect(media_type.parameters).to be(:equal?, parameters)
	end
	
	it "rejects compatible media range objects with wildcards" do
		compatible = Struct.new(:type, :subtype, :parameters).new("text", "*", {})
		
		expect{subject.for(compatible)}.to raise_exception(ArgumentError)
	end
	
	it "compares equivalent values" do
		other = subject.parse('text/plain; charset=utf-8; title="Plain Text"')
		
		expect(type).to be == other
		expect(type.hash).to be == other.hash
	end
	
	it "distinguishes parameters" do
		expect(type).not.to be == subject.parse("text/plain")
	end
end
