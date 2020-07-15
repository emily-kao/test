FETCH_DIR := build/base
OUTPUT_DIR := config-root

.PHONY: clean
clean:
	rm -rf build $(OUTPUT_DIR)

init:
	mkdir -p $(FETCH_DIR)
	mkdir -p $(OUTPUT_DIR)/namespaces/jx
	cp -r src/* build
	mkdir -p $(FETCH_DIR)/cluster/crds
	mkdir -p $(FETCH_DIR)/namespaces/nginx
	mkdir -p $(FETCH_DIR)/namespaces/vault-infra


.PHONY: fetch
fetch: init
	jx gitops repository --source-dir $(OUTPUT_DIR)/namespaces
	jx gitops jx-apps template --template-values src/fake-secrets.yaml -o $(OUTPUT_DIR)/namespaces
	jx gitops namespace --dir-mode --dir $(OUTPUT_DIR)/namespaces

.PHONY: build
# uncomment this line to enable kustomize
#build: build-kustomise
build: build-nokustomise

.PHONY: build-kustomise
build-kustomise: kustomize post-build

.PHONY: build-nokustomise
build-nokustomise: copy-resources post-build


.PHONY: pre-build
pre-build:

.PHONY: post-build
post-build:
	jx gitops scheduler -d config-root/namespaces/jx -o src/base/namespaces/jx/lighthouse-config
	jx gitops ingress
	jx gitops label --dir $(OUTPUT_DIR) gitops.jenkins-x.io/pipeline=environment
	jx gitops annotate --dir  $(OUTPUT_DIR)/namespaces --kind Deployment wave.pusher.com/update-on-config-change=true

	# lets force a rolling upgrade of lighthouse pods whenever we update the lighthouse config...
	jx gitops hash -s config-root/namespaces/jx/lighthouse-config/config-cm.yaml -s config-root/namespaces/jx/lighthouse-config/plugins-cm.yaml -d config-root/namespaces/jx/lighthouse

.PHONY: kustomize
kustomize: pre-build
	kustomize build ./build  -o $(OUTPUT_DIR)/namespaces

.PHONY: copy-resources
copy-resources: pre-build
	cp -r ./build/base/* $(OUTPUT_DIR)
	rm $(OUTPUT_DIR)/kustomization.yaml

.PHONY: lint
lint:

.PHONY: verify
verify:
	jx verify env
	jx verify ingress
	jx verify webhooks --verbose --warn-on-fail

.PHONY: apply
apply:
	kubectl apply --prune -l=gitops.jenkins-x.io/pipeline=environment -R -f $(OUTPUT_DIR)

.PHONY: commit
commit:
	git add $(OUTPUT_DIR) *.yml
	git commit -m "chore: regenerated" --allow-empty
	git push

.PHONY: all
all: clean fetch build lint


.PHONY: pr
pr: all commit

.PHONY: release
release: lint

