build:
	nix-shell --run "mdbook build"

serve:
	nix-shell --run "mdbook serve"

docker:
	./scripts/docker.sh

.PHONY: build serve docker
