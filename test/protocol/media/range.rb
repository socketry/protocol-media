# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/media/range"
require "protocol/media/type"

describe Protocol::Media::Range do
	let(:media_range) {subject.parse('text/*; profile="example"')}
	
	it "parses strings with .for" do
		expect(subject.for("text/plain")).to be == subject.parse("text/plain")
	end
	
	it "preserves compatible objects with .for" do
		object = Struct.new(:type, :subtype).new("text", "plain")
		expect(subject.for(object)).to be(:equal?, object)
	end
	
	it "parses a media range" do
		expect(media_range.type).to be == "text"
		expect(media_range.subtype).to be == "*"
		expect(media_range.parameters).to be == {"profile" => "example"}
		expect(media_range.to_s).to be == "text/*; profile=example"
	end
	
	it "defaults to any subtype" do
		expect(subject.new("text").name).to be == "text/*"
	end
	
	it "normalizes names" do
		expect(subject.parse("TEXT/*").name).to be == "text/*"
		expect(subject.build("TEXT", "PLAIN").name).to be == "text/plain"
	end
	
	it "preserves constructed names" do
		expect(subject.new("TEXT", "PLAIN").name).to be == "TEXT/PLAIN"
	end
	
	it "freezes its values" do
		media_range = subject.new(+"TEXT", +"PLAIN", {})
		media_range.freeze
		
		expect(media_range.freeze).to be(:equal?, media_range)
		expect(media_range.type).to be(:frozen?)
		expect(media_range.subtype).to be(:frozen?)
		expect(media_range.parameters).to be(:frozen?)
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
		media_range = subject.parse("application/json; version=2")
		type = Protocol::Media::Type.parse("application/json")
		
		expect(media_range).to be === type
	end
	
	it "compares equivalent values" do
		other = subject.parse('text/*; profile="example"')
		
		expect(media_range).to be == other
		expect(media_range.hash).to be == other.hash
	end
end
