# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/media/range"
require "protocol/media/type"

describe Protocol::Media::Range do
	let(:range) {subject.parse('text/*; profile="example"')}
	
	it "parses strings with .for" do
		expect(subject.for("text/plain")).to be == subject.parse("text/plain")
	end
	
	it "preserves compatible objects with .for" do
		object = Struct.new(:type, :subtype).new("text", "plain")
		expect(subject.for(object)).to be(:equal?, object)
	end
	
	it "parses a media range" do
		expect(range.type).to be == "text"
		expect(range.subtype).to be == "*"
		expect(range.parameters).to be == {"profile" => "example"}
		expect(range.to_s).to be == "text/*; profile=example"
	end
	
	it "defaults to any subtype" do
		expect(subject.new("text").name).to be == "text/*"
	end
	
	it "normalizes names" do
		expect(subject.parse("TEXT/*").name).to be == "text/*"
	end
	
	it "rejects invalid wildcard forms" do
		expect{subject.parse("*/json")}.to raise_exception(ArgumentError)
		expect{subject.parse("text/*+json")}.to raise_exception(ArgumentError)
		expect{subject.parse("te*t/plain")}.to raise_exception(ArgumentError)
	end
	
	it "matches compatible media types" do
		expect(subject.parse("text/*")).to be === Protocol::Media::Type.parse("text/plain")
		expect(subject.parse("*/*")).to be === Protocol::Media::Type.parse("application/json")
		expect(subject.parse("text/plain")).to be === Protocol::Media::Type.parse("text/plain")
	end
	
	it "does not match incompatible media types" do
		expect(subject.parse("text/*")).not.to be === Protocol::Media::Type.parse("application/json")
		expect(subject.parse("text/plain")).not.to be === Protocol::Media::Type.parse("text/html")
	end
	
	it "matches compatible ranges" do
		expect(subject.parse("text/*")).to be === subject.parse("text/plain")
		expect(subject.parse("text/*")).not.to be === subject.parse("application/*")
	end
	
	it "matches independently of parameters" do
		range = subject.parse("application/json; version=2")
		type = Protocol::Media::Type.parse("application/json")
		
		expect(range).to be === type
	end
	
	it "compares equivalent values" do
		other = subject.parse('text/*; profile="example"')
		
		expect(range).to be == other
		expect(range.hash).to be == other.hash
	end
end
