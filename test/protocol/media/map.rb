# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/media/map"
require "protocol/media/type"

describe Protocol::Media::Map do
	let(:json_type) {Protocol::Media::Type.parse("application/json")}
	let(:html_type) {Protocol::Media::Type.parse("text/html")}
	let(:plain_type) {Protocol::Media::Type.parse("text/plain")}
	let(:compatible_media_range) {Struct.new(:type, :subtype, :parameters)}
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
		expect{map["application/xml"] = :xml}.to raise_exception(FrozenError)
	end
	
	it "supports incremental creation" do
		map = subject.new
		map["application/json"] = :json
		map["text/plain"] = :plain
		
		expect(map["text/*"]).to be == :plain
		expect(map.freeze).to be(:equal?, map)
		expect(map["application/json"]).to be == :json
		expect{map["image/png"] = :png}.to raise_exception(FrozenError)
	end
	
	it "invalidates its lookup cache when mutated" do
		map = subject.new
		
		expect(map["application/json"]).to be_nil
		
		map["application/json"] = :json
		
		expect(map["application/json"]).to be == :json
	end
	
	it "does not expose a builder" do
		expect{subject::Builder}.to raise_exception(NameError)
	end
	
	it "does not provide a block builder" do
		expect(subject).not.to be(:respond_to?, :build)
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
		map = subject.new
		map[json_type] = :json
		map[Protocol::Media::Range.parse("application/json; version=2")] = :versioned_json
		map.freeze
		
		expect(map[json_type]).to be == :versioned_json
		expect(map["application/*"]).to be == :versioned_json
		expect(map["*/*"]).to be == :versioned_json
	end
	
	it "keeps the first distinct registration for wildcard queries" do
		map = subject.new
		map["application/json"] = :json
		map["application/pdf"] = :pdf
		map.freeze
		
		expect(map["application/*"]).to be == :json
		expect(map["*/*"]).to be == :json
	end
	
	it "rejects wildcard registrations" do
		expect{subject.for("text/*" => :text)}.to raise_exception(ArgumentError)
		expect{subject.for("*/*" => :default)}.to raise_exception(ArgumentError)
	end
	
	it "matches independently of parameters" do
		expect(map["application/json; version=2"]).to be == :json
	end
	
	it "finds the first preferred media range" do
		media_ranges = [
			Protocol::Media::Range.parse("image/*"),
			Protocol::Media::Range.parse("text/plain; format=flowed"),
		]
		
		expect(map.for(media_ranges)).to be == [:plain, media_ranges.last]
	end
	
	it "accepts compatible media range objects" do
		media_ranges = [
			compatible_media_range.new("IMAGE", "*", {}),
			compatible_media_range.new("TEXT", "PLAIN", {"q" => "0.5"}),
		]
		
		expect(map.for(media_ranges)).to be == [:plain, media_ranges.last]
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
