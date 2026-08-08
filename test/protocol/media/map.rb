# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/media/map"
require "protocol/media/type"

describe Protocol::Media::Map do
	let(:json_type) {Protocol::Media::Type.parse("application/json")}
	let(:html_type) {Protocol::Media::Type.parse("text/html")}
	let(:plain_type) {Protocol::Media::Type.parse("text/plain")}
	let(:compatible_range) {Struct.new(:type, :subtype, :parameters)}
	let(:map) do
		subject.for(
			json_type => :json,
			html_type => :html,
			plain_type => :plain,
		)
	end
	
	it "constructs immutable maps from keyed entries" do
		expect(map).to be(:frozen?)
		expect(subject.for(map)).to be(:equal?, map)
		expect{map["application/xml"] = :xml}.to raise_exception(NoMethodError)
	end
	
	it "constructs immutable maps with a builder" do
		map = subject.build do |builder|
			builder["application/json"] = :json
		end
		
		expect(map["application/json"]).to be == :json
		expect(map).to be(:frozen?)
	end
	
	it "builds independent immutable snapshots" do
		builder = subject::Builder.new
		builder["application/json"] = :json
		first = builder.build
		builder["text/plain"] = :plain
		second = builder.build
		
		expect(first["text/plain"]).to be_nil
		expect(second["text/plain"]).to be == :plain
		expect(first).to be(:frozen?)
		expect(second).to be(:frozen?)
	end
	
	it "looks up exact media types" do
		expect(map["application/json"]).to be == :json
		expect(map[Protocol::Media::Range.parse("text/plain")]).to be == :plain
	end
	
	it "looks up compatible media ranges" do
		expect(map["text/*"]).to be == :html
		expect(map["*/*"]).to be == :json
	end
	
	it "uses the first registration for wildcard queries" do
		map = subject.for(
			"application/json" => :json,
			"text/plain" => :plain,
		)
		
		expect(map["text/*"]).to be == :plain
		expect(map["*/*"]).to be == :json
	end
	
	it "replaces an existing type/subtype registration" do
		map = subject.build do |builder|
			builder[json_type] = :json
			builder[Protocol::Media::Range.parse("application/json; version=2")] = :versioned_json
		end
		
		expect(map[json_type]).to be == :versioned_json
		expect(map["application/*"]).to be == :json
	end
	
	it "rejects wildcard registrations" do
		expect{subject.for("text/*" => :text)}.to raise_exception(ArgumentError)
		expect{subject.for("*/*" => :default)}.to raise_exception(ArgumentError)
	end
	
	it "matches independently of parameters" do
		expect(map["application/json; version=2"]).to be == :json
	end
	
	it "finds the first preferred media range" do
		ranges = [
			Protocol::Media::Range.parse("image/*"),
			Protocol::Media::Range.parse("text/plain; format=flowed"),
		]
		
		expect(map.for(ranges)).to be == [:plain, ranges.last]
	end
	
	it "accepts compatible media range objects" do
		ranges = [
			compatible_range.new("IMAGE", "*", {}),
			compatible_range.new("TEXT", "PLAIN", {"q" => "0.5"}),
		]
		
		expect(map.for(ranges)).to be == [:plain, ranges.last]
	end
	
	it "preserves string ranges when finding a preferred match" do
		expect(map.for(["image/*", "application/json"])).to be == [:json, "application/json"]
	end
	
	it "returns nil when there is no compatible registration" do
		expect(map["image/png"]).to be_nil
		expect(map.for(["image/*"])).to be_nil
	end
	
	it "does not freeze mapped objects" do
		object = Object.new
		map = subject.for("application/xml" => object)
		
		expect(object).not.to be(:frozen?)
		expect(map["application/xml"]).to be(:equal?, object)
	end
end
