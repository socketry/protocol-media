# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/media/set"
require "protocol/media/type"

describe Protocol::Media::Set do
	let(:set) {subject.new("image/*", "application/pdf")}
	let(:compatible_range) {Struct.new(:type, :subtype, :parameters)}
	
	it "matches compatible media types" do
		expect(set).to be(:include?, Protocol::Media::Type.parse("image/png"))
		expect(set).to be(:include?, "application/pdf")
		expect(set).to be === Protocol::Media::Range.parse("image/jpeg")
		expect(set).to be(:include?, "image/*")
		expect(set).to be(:include?, "application/*")
		expect(set).to be(:include?, "*/*")
	end
	
	it "matches a global wildcard" do
		set = subject.new("*/*")
		
		expect(set).to be(:include?, "application/json")
		expect(set).to be(:include?, "text/*")
		expect(set).not.to be(:empty?)
	end
	
	it "does not match incompatible media types" do
		expect(set).not.to be(:include?, "text/plain")
	end
	
	it "matches independently of parameters" do
		expect(set).to be(:include?, "application/pdf; version=2")
	end
	
	it "accepts compatible media range objects" do
		set << compatible_range.new("TEXT", "*", {})
		
		expect(set).to be(:match?, compatible_range.new("text", "plain", {}))
	end
	
	it "enumerates canonical membership ranges" do
		set.add("image/*; profile=example")
		
		expect(set.size).to be == 2
		expect(set.first.parameters).to be(:empty?)
		expect(set.first).to be(:frozen?)
	end
	
	it "enumerates membership ranges" do
		expect(set.each).to be_a(Enumerator)
		expect(set.map(&:name)).to be == ["image/*", "application/pdf"]
	end
	
	it "removes entries covered by a type wildcard" do
		set = subject.new("image/png", "application/pdf", "image/jpeg")
		set << "image/*"
		
		expect(set.map(&:name).sort).to be == ["application/pdf", "image/*"]
	end
	
	it "ignores entries covered by a wildcard" do
		set << "image/png"
		
		expect(set.map(&:name)).to be == ["image/*", "application/pdf"]
	end
	
	it "removes all entries covered by the universal wildcard" do
		set << "*/*"
		set << "text/plain"
		
		expect(set.map(&:name)).to be == ["*/*"]
	end
	
	it "can be empty" do
		empty = subject.new
		
		expect(empty).to be(:empty?)
		expect(empty.size).to be == 0
	end
	
	it "can be frozen without freezing compatible objects" do
		range = compatible_range.new("text", "plain", {})
		set << range
		set.freeze
		
		expect(set.freeze).to be(:equal?, set)
		expect(range).not.to be(:frozen?)
		expect{set << "text/html"}.to raise_exception(FrozenError)
	end
end
