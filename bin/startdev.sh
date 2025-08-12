perl generate_docs.pl > /dev/null

plackup --env development --server Plack::Handler::Standalone --app lacuna.psgi
