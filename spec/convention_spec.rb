require "spec_helper"
require "nginxbrew"
require "nginxbrew/convention"

include Nginxbrew


describe Nginxbrew::NamingConvention, "controls versions/builds in local env" do

    it "make package name from version for nginx" do
        ret = NamingConvention.package_name_from("1.1.1", false)
        expect(ret).to eq "ngx-1.1.1"
    end

    it "make package name from version for openresty" do
        ret = NamingConvention.package_name_from("1.1.1", true)
        expect(ret).to eq "ngx-openresty-1.1.1"
    end

    it "can get correct version from package name" do
        ret = NamingConvention.version_from_package("ngx-1.1.1")
        expect(ret).to eq "1.1.1"
    end

    it "raise error if package name is invalid (prefix is wrong)" do
        expect {
            NamingConvention.version_from_package("INVALID-1.1.1")
        }.to raise_error
    end

    it "raise error if package name is invalid (only prefix)" do
        expect {
            NamingConvention.version_from_package("ngx-")
        }.to raise_error
    end

    it "true/false from openresty?" do
        expect(NamingConvention.openresty?("openresty-1.1.1")).to be_truthy
        expect(NamingConvention.openresty?("NOTOPENRESTY-1.1.1")).to be_falsey
    end

    it "can get raw version from openresty" do
        ret = NamingConvention.openresty_to_raw_version("openresty-1.1.1")
        expect(ret).to eq "1.1.1"  
    end

    it "resolve ngx versions" do
        ret = NamingConvention.resolve("1.1.1")
        expect(ret).to match_array ["1.1.1", false]
    end

    it "resolve openresty versions" do
        ret = NamingConvention.resolve("openresty-1.1.1")
        expect(ret).to match_array ["1.1.1", true]
    end

end
