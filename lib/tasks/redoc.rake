require "rake"

# Rake tasks for openapi spec
namespace :redoc do
  desc "Bundle the openapi.yml"
  task :bundle do
    %x(
      docker run -v /workspaces/astral/doc/openapi:/data -w /data \
      redocly/cli bundle openapi.yml \
      --output openapi-bundled.yml
    )
    puts "openapi.yml and references bundled to openapi-bundled.yml"
  end

  desc "Move bundled api spec to public hosting location"
  task :publish do
    %x(
      sudo chown vscode:vscode doc/openapi/openapi-bundled.yml
      mv doc/openapi/openapi-bundled.yml public/doc/
    )
    puts "openapi-bundled.yml moved to public hosting location"
  end

end
