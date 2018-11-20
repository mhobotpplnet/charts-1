UPSTREAM_GIT_URL = https://github.com/buildkite/charts.git
CHARTS_URL = https://buildkite.github.io/charts
CT_IMAGE = gcr.io/kubernetes-charts-ci/test-image:v3.0.1

.PHONY: lint shellcheck clean build publish

# Lints the chart changes against origin/master
lint:
	git fetch origin master && \
		docker run \
			--volume "${PWD}:/src" \
			--workdir /src \
			--rm \
			"${CT_IMAGE}" \
			ct lint --config test/ct.yaml

# Runs shellcheck over any shell files
shellcheck:
	docker run \
		--volume "${PWD}:/src" \
		--workdir /src \
		--rm \
		koalaman/shellcheck-alpine \
		sh -c "shellcheck -x **/*.sh"

clean:
	rm -rf dist-repo

dist-repo:
	git clone --quiet --single-branch -b gh-pages "${UPSTREAM_GIT_URL}" dist-repo

# Build all Helm packages into dist-repo and regenerate the chart index
build: dist-repo
	cd package && \
		docker-compose build && \
		docker-compose run --rm package package.sh "${CHARTS_URL}" dist-repo && \
		cd ../dist-repo && \
		echo "--- Diff" && \
		git diff --stat

# Commit and push the chart index
publish: dist-repo build
	cd dist-repo && \
		git add *.tgz index.yaml && \
		git commit --message "Update buildkite/charts" && \
		git push -q upstream HEAD:gh-pages