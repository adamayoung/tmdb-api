#!make

DOCKER_PLATFORM = linux/amd64/v2
DOCKER_BUILD_IMAGE_NAME = tmdbapibuilder

-include .env

.PHONY: clean
clean:
	swift package clean
	rm -rf .build .aws-sam archives

.PHONY: format
format:
	swiftlint --fix
	swiftformat .

.PHONY: lint
lint:
	swiftlint --strict
	swiftformat --lint .

.PHONY: lint-markdown
lint-markdown:
	markdownlint "README.md"

.PHONY: prepare
prepare:
	docker build . --platform "$(DOCKER_PLATFORM)" -t $(DOCKER_BUILD_IMAGE_NAME)

.PHONY: resolve
resolve:
	docker run --rm --platform "$(DOCKER_PLATFORM)" -v "$${PWD}:/workspace" -w /workspace $(DOCKER_BUILD_IMAGE_NAME) bash -cl "swift package resolve"

.PHONY: build
build:
	docker run --rm --platform "$(DOCKER_PLATFORM)" -v "$${PWD}:/workspace" -w /workspace $(DOCKER_BUILD_IMAGE_NAME) bash -cl "swift build"

.PHONY: build-for-testing
build-for-testing:
	docker run --rm --platform "$(DOCKER_PLATFORM)" -v "$${PWD}:/workspace" -w /workspace $(DOCKER_BUILD_IMAGE_NAME) bash -cl "swift build --build-tests"

.PHONY: test-without-building
test-without-building:
	docker run --rm --platform "$(DOCKER_PLATFORM)" -v "$${PWD}:/workspace" -w /workspace $(DOCKER_BUILD_IMAGE_NAME) bash -cl "swift test --skip-build"

.PHONY: test
test: build-for-testing test-without-building

.PHONY: archive
archive:
	mkdir -p archives
	docker run --rm --platform "$(DOCKER_PLATFORM)" -v "$${PWD}:/workspace" -w /workspace $(DOCKER_BUILD_IMAGE_NAME) bash -cl "swift package archive --output-path archives --verbose 2"
	ls -d archives/*/* | grep -v \.zip$ | xargs rm

.PHONY: validate-sam-template
validate-sam-template:
	sam validate --lint

.PHONY: build-sam-template
build-sam-template:
	sam build

.PHONY: deploy-without-archive
deploy-without-archive: .check-deploy-env-vars
	sam deploy \
		--no-confirm-changeset \
		--no-fail-on-empty-changeset \
		--resolve-s3 \
		--stack-name "${AWS_STACK}" \
		--capabilities CAPABILITY_IAM \
		--region "${AWS_REGION}"

.PHONY: deploy
deploy: build-sam-template archive deploy-without-archive

.PHONY: ci
ci: clean resolve prepare validate-sam-template build-sam-template archive deploy-without-archive

.check-deploy-env-vars:
	@test -n "$(AWS_STACK)" || (echo 'AWS_STACK environment variable not set' && exit 1)
	@test -n "$(AWS_REGION)" || (echo 'AWS_REGION environment variable not set' && exit 1)
