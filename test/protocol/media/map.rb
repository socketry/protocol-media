# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/media/map"
require "protocol/media/type"

describe Protocol::Media::Map do
	let(:map) {subject.new}
	let(:json_type) {Protocol::Media::Type.parse("application/json")}
	let(:html_type) {Protocol::Media::Type.parse("text/html")}
	let(:plain_type) {Protocol::Media::Type.parse("text/plain")}
	
	before do
		map[json_type] = :json
		map[html_type] = :html
		map[plain_type] = :plain
	end
	
	it "looks up exact media types" do
		expect(map["application/json"]).to be == :json
		expect(map[Protocol::Media::Range.parse("text/plain")]).to be == :plain
	end
	
	it "looks up compatible media ranges" do
		expect(map["text/*"]).to be == :html
		expect(map["*/*"]).to be == :json
	end
	
	it "prefers an exact range registration" do
		map["text/*"] = :text
		map["*/*"] = :default
		
		expect(map["text/*"]).to be == :text
		expect(map["*/*"]).to be == :default
		expect(map["text/html"]).to be == :html
	end
	
	it "replaces an existing type/subtype registration" do
		map[Protocol::Media::Range.parse("application/json; version=2")] = :versioned_json
		
		expect(map[json_type]).to be == :versioned_json
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
	
	it "preserves string ranges when finding a preferred match" do
		expect(map.for(["image/*", "application/json"])).to be == [:json, "application/json"]
	end
	
	it "returns nil when there is no compatible registration" do
		expect(map["image/png"]).to be_nil
		expect(map.for(["image/*"])).to be_nil
	end
	
	it "rejects unsupported keys" do
		expect{map[Object.new]}.to raise_exception(TypeError)
	end
	
	it "can be frozen without freezing mapped objects" do
		object = Object.new
		map["application/xml"] = object
		map.freeze
		
		expect(map).to be(:frozen?)
		expect(object).not.to be(:frozen?)
		expect{map["text/xml"] = Object.new}.to raise_exception(FrozenError)
	end
end
