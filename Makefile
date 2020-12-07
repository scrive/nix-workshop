build:
	nix-shell --run "mdbook build"

serve:
	nix-shell --run "mdbook serve"

docker:
	docker build --tag nix-workshop .
	docker run --rm -it -v ${pwd}:/nix-workshop nix-workshop

.PHONY: build serve docker
