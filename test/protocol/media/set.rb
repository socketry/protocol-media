# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/media/set"
require "protocol/media/type"

describe Protocol::Media::Set do
	let(:set) {subject.for(["image/*", "application/pdf"])}
	let(:compatible_media_range) {Struct.new(:type, :subtype, :parameters)}
	
	it "hides its universal implementation" do
		expect{subject::Any}.to raise_exception(NameError)
		expect{subject::ANY}.to raise_exception(NameError)
	end
	
	it "does not expose a builder" do
		expect{subject::Builder}.to raise_exception(NameError)
	end
	
	it "does not provide a block builder" do
		expect(subject).not.to be(:respond_to?, :build)
	end
	
	it "constructs immutable sets from ranges" do
		expect(set).to be(:frozen?)
		expect(subject.for(set)).to be(:equal?, set)
		expect{set << "text/plain"}.to raise_exception(FrozenError)
	end
	
	it "supports incremental creation" do
		set = subject.new
		set << "application/json"
		set << "text/*"
		
		expect(set).to be(:include?, "text/plain")
		expect(set.freeze).to be(:equal?, set)
		expect(set).to be(:include?, "application/json")
		expect{set << "image/png"}.to raise_exception(FrozenError)
	end
	
	it "invalidates its lookup cache when mutated" do
		set = subject.new
		
		expect(set).not.to be(:include?, "application/json")
		
		set << "application/json"
		
		expect(set).to be(:include?, "application/json")
	end
	
	it "matches compatible media types" do
		expect(set).to be(:include?, Protocol::Media::Type.parse("image/png"))
		expect(set).to be(:include?, "application/pdf")
		expect(set).to be === Protocol::Media::Range.parse("image/jpeg")
		expect(set).to be(:include?, "image/*")
		expect(set).to be(:include?, "application/*")
		expect(set).to be(:include?, "*/*")
	end
	
	it "matches a global wildcard" do
		set = subject.for(["*/*"])
		
		expect(subject.for(["*/*"])).to be(:equal?, set)
		expect(subject.for(set)).to be(:equal?, set)
		expect(set).to be(:frozen?)
		expect(set).to be(:universal?)
		expect(set).to be(:include?, "application/json")
		expect(set).to be(:include?, "text/*")
		expect(set).not.to be(:empty?)
	end
	
	it "distinguishes wildcard compatibility from universal membership" do
		set = subject.new(["image/png"])
		
		expect(set).to be(:include?, "*/*")
		expect(set).not.to be(:universal?)
		
		set << "*/*"
		
		expect(set).to be(:universal?)
		expect(set).to be(:include?, "text/plain")
		expect(set.map(&:name)).to be == ["*/*"]
		expect(set.size).to be == 1
		expect(set).not.to be(:empty?)
	end
	
	it "does not match incompatible media types" do
		expect(set).not.to be(:include?, "text/plain")
	end
	
	it "matches independently of parameters" do
		expect(set).to be(:include?, "application/pdf; version=2")
	end
	
	it "accepts compatible media range objects" do
		set = subject.for([compatible_media_range.new("TEXT", "*", {})])
		
		expect(set).to be(:match?, compatible_media_range.new("text", "plain", {}))
	end
	
	it "rejects invalid wildcards in compatible media range objects" do
		media_range = compatible_media_range.new("*", "json", {})
		
		expect{subject.for([media_range])}.to raise_exception(ArgumentError)
		expect{set.include?(media_range)}.to raise_exception(ArgumentError)
	end
	
	it "enumerates canonical membership ranges" do
		set = subject.for(["application/pdf", "image/*; profile=example"])
		
		expect(set.size).to be == 2
		expect(set.first.parameters).to be(:empty?)
	end
	
	it "enumerates membership ranges" do
		expect(set.each).to be_a(Enumerator)
		expect(set.map(&:name)).to be == ["image/*", "application/pdf"]
	end
	
	it "removes entries covered by a type wildcard" do
		set = subject.for(["image/png", "application/pdf", "image/jpeg", "image/*"])
		
		expect(set.map(&:name).sort).to be == ["application/pdf", "image/*"]
	end
	
	it "ignores entries covered by a wildcard" do
		set = subject.for(["image/*", "application/pdf", "image/png"])
		
		expect(set.map(&:name)).to be == ["image/*", "application/pdf"]
	end
	
	it "removes all entries covered by the universal wildcard" do
		set = subject.for(["image/*", "*/*", "text/plain"])
		
		expect(set.map(&:name)).to be == ["*/*"]
	end
	
	it "can be empty" do
		empty = subject.for([])
		
		expect(empty).to be(:empty?)
		expect(empty.size).to be == 0
	end
	
	it "does not freeze compatible objects" do
		media_range = compatible_media_range.new("text", "plain", {})
		set = subject.for([media_range])
		
		expect(media_range).not.to be(:frozen?)
		expect(set).to be(:include?, media_range)
	end
end
