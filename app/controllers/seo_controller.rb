class SeoController < ApplicationController
  def sitemap
    @urls = [root_url(host: canonical_host, protocol: "https")]
  end
end
