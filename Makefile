all: build

.PHONY: build

build:
	docker build --rm -t docxs/dockermail .
