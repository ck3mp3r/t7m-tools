# t7m-tools
Terraform, kubectl, helm and aws cli plus a helper script.

## Run locally

You can create an alias that will allow you to run all the tools from within the container...
```
alias t7m-tools='docker run --rm -it \
-v ~/.ssh:/root/.ssh \
-v ~/.aws:/root/.aws \
-v ~/.kube:/root/.kube \
-v `pwd`:/workspaces \
-w /workspaces \
ckemper/t7m-tools:latest'
```

Subsequent runs of `t7m-tools` will place you in the bash and cd you into `/workspaces`.
It will also mount `~/.ssh`, `~/.aws` and `~/.kube` so your settings are immediately available.

## tf cli helper

An addition to the tools is `tf`
It has the following options:
* `-e <env> | --env <env>` environment to be used. It expects `var/<env>.hcl` and `var/<env>.tfvars` to be present.
* `-i | --init`: initialize terraform. You only need to include this flag on first run or if you switch from one `<env>` to another.
* `-c:--color`: show colorful output.

Some examples:
* `tf -e env2 -i -c plan` run plan on env2 after initializing with color output.
* `tf -e env1 -c apply` run apply on env1 with color output.
* `tf -e env3 apply -auto-approve` run non interactive apply.
