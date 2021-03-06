require "moneta"
require "mustache"

%w(authlogic devise devise/version).each do |lib|
  begin
    require lib
  rescue LoadError
  end
end

require "rich/cms/core"
require "rich/cms/actionpack"
require "rich/cms/engine"
require "rich/cms/auth"
require "rich/cms/content"
require "rich/cms/moneta"
require "rich/cms/version"
