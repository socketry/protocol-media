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
	
	it "replaces an existing type/subtype registration" do
		set.add("image/*; profile=example")
		
		expect(set.size).to be == 2
		expect(set.first.parameters).to be == {"profile" => "example"}
	end
	
	it "enumerates ranges in insertion order" do
		expect(set.each).to be_a(Enumerator)
		expect(set.map(&:name)).to be == ["image/*", "application/pdf"]
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
