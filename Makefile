TOOLS_VERSION=1.3.0

build:
	docker build -t ckemper/t7m-tools:${TOOLS_VERSION} .

publish:
	docker push \
		ckemper/t7m-tools:${TOOLS_VERSION}

publish-latest:
	docker tag \
		ckemper/t7m-tools:${TOOLS_VERSION} \
		ckemper/t7m-tools:latest
	docker push \
		ckemper/t7m-tools:latest
