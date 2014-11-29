require "spec_helper"
require "nginxbrew"
require "nginxbrew/catalog"

require "fileutils"


describe Nginxbrew::Catalog, "scraping ngx versions in their page" do

    before(:each) do
        @cache_dir = File.join("/tmp", File.dirname(__FILE__), "cache")
        FileUtils.mkdir_p(@cache_dir)
    end
    
    after(:each) do
        FileUtils.rm_rf(@cache_dir)
    end

    it "should return list of nginx versions" do
        ret = Nginxbrew::Catalog.nginxes
        expect(ret.size).to be > 0
        expect(ret.ngx_type).to eq Nginxbrew::Catalog::TypeNginx
    end

    it "version text in nginxes is [0-9.]+" do
        ret = Nginxbrew::Catalog.nginxes
        ret.versions.each do |v|
            expect(v).to match(/[0-9.]+/)
        end
    end

    it "cache of nginxes should be created and can read it" do
        Nginxbrew::Catalog.nginxes(cache_dir=@cache_dir)
        expect(FileTest.file?(File.join(@cache_dir, "catalog/nginxes.ca"))).to be_truthy

        ret = Nginxbrew::Catalog.nginxes
        expect(ret.size).to be > 0
    end

    it "cache of openresties should be created and can read it" do
        Nginxbrew::Catalog.openresties(cache_dir=@cache_dir)
        expect(FileTest.file?(File.join(@cache_dir, "catalog/openresties.ca"))).to be_truthy

        ret = Nginxbrew::Catalog.openresties
        expect(ret.size).to be > 0
    end

    it "should return list of openresty versions" do
        ret = Nginxbrew::Catalog.openresties
        expect(ret.size).to be > 0
        expect(ret.ngx_type).to eq Nginxbrew::Catalog::TypeOpenresty
    end

    it "version text in openresties is [0-9.]+" do
        ret = Nginxbrew::Catalog.openresties
        ret.versions.each do |v|
            expect(v).to match(/[0-9.]+/)
        end
    end

end


describe Nginxbrew::Catalog, "version control" do

    it "should be raised exception when input invalid ngx type" do
        expect {
            Nginxbrew::Catalog.new("INVALID_NGX_TYPE", ["1", "2", "3"])
        }.to raise_error
    end

    it "should be raised exception when version list is empty" do
        expect {
            Nginxbrew::Catalog.new(Nginxbrew::Catalog::TypeNginx, [])
        }.to raise_error
    end

    it "should be raised exception when version is not found in head_of" do
        expect {
            Nginxbrew::Catalog.new(Nginxbrew::Catalog::TypeNginx, ["1", "2", "3"]).head_of("INVALID_VERSION")
        }.to raise_error
    end

    it "should be raised exception when version is not found in filter_versions" do
        expect {
            Nginxbrew::Catalog.new(Nginxbrew::Catalog::TypeNginx, ["1", "2", "3"]).filter_versions("INVALID_VERSION")
        }.to raise_error
    end

    it "can know size of versions" do
        nginxes = Nginxbrew::Catalog.new(Nginxbrew::Catalog::TypeNginx, ["0.0.0", "0.0.1"])
        expect(nginxes.size).to eq 2
    end

    it "filter_versions should return list of active versions" do
        nginxes = Nginxbrew::Catalog.new(
            Nginxbrew::Catalog::TypeNginx,
            %w(0.1 0.2 0.3 1.1 1.2 1.3 2.0.0 2.0.1 2.1.0 2.1.1)
        )
        expect(nginxes.filter_versions("1")).to eq ["1.3", "1.2", "1.1"]
        expect(nginxes.filter_versions("2.1")).to eq ["2.1.1", "2.1.0"]
    end

    it "versions should be sorted order by version-number desc" do
        nginxes = Nginxbrew::Catalog.new(
            Nginxbrew::Catalog::TypeNginx,
            %w(0.0.1 0.0.2 0.1.0 0.1.1 1.0.0 1.0.1 1.1.0 2.15.1 2.8.15)
        )
        expect(nginxes.versions).to eq %w(2.15.1 2.8.15 1.1.0 1.0.1 1.0.0 0.1.1 0.1.0 0.0.2 0.0.1)
    end

    it "head_of should returns head of versions" do
        nginxes = Nginxbrew::Catalog.new(
            Nginxbrew::Catalog::TypeNginx,
            %w(0.0.0 0.0.1 0.1.0 0.1.1 1.0.0 2.0.0)
        )
        expect(nginxes.head_of("0.0")).to eq "0.0.1"
        expect(nginxes.head_of("0.1")).to eq "0.1.1"
        expect(nginxes.head_of("0")).to eq "0.1.1"
    end

    it "head_of is first element of versions which sorted by version number" do
        nginxes = Nginxbrew::Catalog.new(
            Nginxbrew::Catalog::TypeNginx,
            %w(1.5.8.1 1.5.12.1 1.5.11.1)
        )
        expect(nginxes.head_of("1.5")).to eq "1.5.12.1"
        expect(nginxes.head_of("1")).to eq "1.5.12.1"
    end

    it "limit the active version" do
        catalog = Nginxbrew::Catalog.new(
            Nginxbrew::Catalog::TypeNginx,
            %w(0.1 0.2 0.3)
        )
        catalog.unsupport_under!("0.2")
        expect(catalog.versions).to eq %w(0.3 0.2)
    end

end
