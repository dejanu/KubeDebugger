.DEFAULT_GOAL := documentation

documentation:
	@echo "flex"
	@echo "startapp"
	@echo "naked_pod"
	@echo "curl_pod"
	@echo "declarative_deploy"
	@echo "imperative_deploy"
	@echo "imperative_safe"
	@echo "imperative_service"
	@echo "patch_service"
	@echo "deploy_checks"
	@echo "deploy_change_image"

startapp:
	@echo "docker run -p 8888:8888 dejanualex/go_hello:1.0"

oldflex:
	@echo "kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" | jq .items[].usage
flex:
	@echo "kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods | jq .items[].containers[].usage"
curl_pod:
	@echo "kubectl run curlpod -i --tty --image=dejanualex/curlopenssl:1.0 --rm -- sh"
naked_pod:
	@echo "kubectl run nakedpod --image=nginx:stable-alpine-perl"
declarative_deploy:
	@echo "kubectl apply -f deployment.yaml"
imperative_deploy:
	@echo "kubectl create deployment webapp --image=dejanualex/go_hello:1.0 --replicas=2"
imperative_safe:
	@echo "kubectl create deployment webapp --image=dejanualex/go_hello:1.0 --replicas=2 --dry-run=client -oyaml"
imperative_service:
	@echo "kubectl expose deploy webapp --name=webapp-svc --type="ClusterIP" --port=8080 --target-port=8888"
patch_service:
	@echo "kubectl patch svc webapp-svc -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'"
deploy_checks:
	@echo "kubectl rollout status deployment webapp"
	@echo "kubectl rollout history deployment webapp"
	@echo "kubectl rollout history deployment webapp --revision=1"
	@echo "kubectl rollout undo deployment webapp --to-revision=1"
deploy_change_image:
	@echo "kubectl set image deployment webapp <container>=dejanualex/go_hello:1.1"
