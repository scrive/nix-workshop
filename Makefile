build:
	nix-shell --run "mdbook build"

serve:
	nix-shell --run "mdbook serve"

.PHONY: build serve