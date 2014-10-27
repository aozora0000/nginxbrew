require "spec_helper"
require "nginxbrew"
require "nginxbrew/nginxes"


describe Nginxbrew::Nginxes, "scraping ngx versions in their page" do

    it "should return list of nginx versions" do
        ret = Nginxbrew::Nginxes.nginxes
        expect(ret.size).to be > 0
        expect(ret.ngx_type).to eq Nginxbrew::Nginxes::TypeNginx
    end

    it "version text in nginxes is [0-9.]+" do
        ret = Nginxbrew::Nginxes.nginxes
        ret.versions.each do |v|
            expect(v).to match(/[0-9.]+/)
        end
    end

    it "should return list of openresty versions" do
        ret = Nginxbrew::Nginxes.openresties
        expect(ret.size).to be > 0
        expect(ret.ngx_type).to eq Nginxbrew::Nginxes::TypeOpenresty
    end

    it "version text in openresties is [0-9.]+" do
        ret = Nginxbrew::Nginxes.openresties
        ret.versions.each do |v|
            expect(v).to match(/[0-9.]+/)
        end
    end

end


describe Nginxbrew::Nginxes, "version control" do

    it "should be raised exception when input invalid ngx type" do
        expect {
            Nginxbrew::Nginxes.new("INVALID_NGX_TYPE", ["1", "2", "3"])
        }.to raise_error
    end

    it "should be raised exception when version list is empty" do
        expect {
            Nginxbrew::Nginxes.new(Nginxbrew::Nginxes::TypeNginx, [])
        }.to raise_error
    end

    it "should be raised exception when version is not found in head_of" do
        expect {
            Nginxbrew::Nginxes.new(Nginxbrew::Nginxes::TypeNginx, ["1", "2", "3"]).head_of("INVALID_VERSION")
        }.to raise_error
    end

    it "should be raised exception when version is not found in filter_versions" do
        expect {
            Nginxbrew::Nginxes.new(Nginxbrew::Nginxes::TypeNginx, ["1", "2", "3"]).filter_versions("INVALID_VERSION")
        }.to raise_error
    end

    it "can know size of versions" do
        nginxes = Nginxbrew::Nginxes.new(Nginxbrew::Nginxes::TypeNginx, ["0.0.0", "0.0.1"])
        expect(nginxes.size).to eq 2
    end

    it "filter_versions should return list of active versions" do
        nginxes = Nginxbrew::Nginxes.new(
            Nginxbrew::Nginxes::TypeNginx,
            %w(0.1 0.2 0.3 1.1 1.2 1.3 2.0.0 2.0.1 2.1.0 2.1.1)
        )
        expect(nginxes.filter_versions("1")).to eq ["1.3", "1.2", "1.1"]
        expect(nginxes.filter_versions("2.1")).to eq ["2.1.1", "2.1.0"]
    end

    it "versions should be sorted order by version-number desc" do
        nginxes = Nginxbrew::Nginxes.new(
            Nginxbrew::Nginxes::TypeNginx,
            %w(0.0.1 0.0.2 0.1.0 0.1.1 1.0.0 1.0.1 1.1.0 2.15.1 2.8.15)
        )
        expect(nginxes.versions).to eq %w(2.15.1 2.8.15 1.1.0 1.0.1 1.0.0 0.1.1 0.1.0 0.0.2 0.0.1)
    end

    it "head_of should returns head of versions" do
        nginxes = Nginxbrew::Nginxes.new(
            Nginxbrew::Nginxes::TypeNginx,
            %w(0.0.0 0.0.1 0.1.0 0.1.1 1.0.0 2.0.0)
        )
        expect(nginxes.head_of("0.0")).to eq "0.0.1"
        expect(nginxes.head_of("0.1")).to eq "0.1.1"
        expect(nginxes.head_of("0")).to eq "0.1.1"
    end

    it "head_of is first element of versions which sorted by version number" do
        nginxes = Nginxbrew::Nginxes.new(
            Nginxbrew::Nginxes::TypeNginx,
            %w(1.5.8.1 1.5.12.1 1.5.11.1)
        )
        expect(nginxes.head_of("1.5")).to eq "1.5.12.1"
        expect(nginxes.head_of("1")).to eq "1.5.12.1"
    end

end
