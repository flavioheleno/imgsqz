build-pngcrush:
	podman build --file Dockerfile --tag img-sqz:pngcrush --target build-pngcrush

run-pngcrush:
	podman run --rm --tty --interactive --volume $(shell pwd -P):/app --workdir /app img-sqz:pngcrush


build-optipng:
	podman build --file Dockerfile --tag img-sqz:optipng --target build-optipng

run-optipng:
	podman run --rm --tty --interactive --volume $(shell pwd -P):/app --workdir /app img-sqz:optipng


build-jpegoptim:
	podman build --file Dockerfile --tag img-sqz:jpegoptim --target build-jpegoptim

run-jpegoptim:
	podman run --rm --tty --interactive --volume $(shell pwd -P):/app --workdir /app img-sqz:jpegoptim


build-guetzli:
	podman build --file Dockerfile --tag img-sqz:guetzli --target build-guetzli

run-guetzli:
	podman run --rm --tty --interactive --volume $(shell pwd -P):/app --workdir /app img-sqz:guetzli


build-mozjpeg:
	podman build --file Dockerfile --tag img-sqz:mozjpeg --target build-mozjpeg

run-mozjpeg:
	podman run --rm --tty --interactive --volume $(shell pwd -P):/app --workdir /app img-sqz:mozjpeg


build:
	podman build --file Dockerfile --tag img-sqz:latest

run:
	podman run --rm --tty --interactive --volume $(shell pwd -P):/app img-sqz:latest
