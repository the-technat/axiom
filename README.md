# [axiom](https://pixar.fandom.com/wiki/Axiom)

My personal Kubernetes cluster to host all my stuff.

## Why?

As a computer scientist you tend to solve IT problems with custom solutions. Some might programm their own app, others might search for an app and selfhost it. So do I. I got the following services that are hosted at some providers, sometimes maintained by me and sometimes as a Service:

- cloud.technat.ch: My personal Nextcloud
- collabora-online.fly.dev: Collabora Online Server used within the Nextcloud to edit rich-text documents
- vpn.technat.ch: A VPN service to securly browse the web from abroad
- flasche.alleaffengaffen.ch: The minecraft server of my colleagues (I'm not a gamer, but I can host servers)
- foto.js-buchsi.ch: [Lychee](https://lycheeorg.github.io/) based photo gallery
- many more projects to come in the future

Now I realized that they are spread over a dozent of different providers, all requiring some sort of monthly fee for their service. Although most of them have a good prive/value ratio, some apps don't. So the goal of axiom is to create a "centralized" place for all these services, so that we have:
- one fee
- all services in one place and under my control
- a home for new projects coming up
- something to practice your IT knowledge on

Before we dive into the details of the solution, let's define some hard requirements the solution must offer:

- backup: we host productive services there that must have some serious backup-system
- low maintenance effort: the inital effort might be high, but maintenance once every two months or less frequent is desirable
- scalability: when we need more compute, we simple add new servers (horizontal scaling)
- potential for high-availbility: we don't build HA, but we also don't intentionally prevent it. As much as possible the solution should be designed so that HA is possible. Exceptions are allowed if the effort/cost is not worth it

### A word about privacy

If someone hosts services on there own, one of the primary goals he has might be privacy. Now you haven't read this word in my concept so far, because that's not my primary focus. Of course privacy will be a lot better with self-hosted services, but it could be made better by far. Just think about Tailscale. Theoretically they could know everything what's happening. In addition data (either backup or block-storage) is stored on a provider, so you have to trust them that your data is secure there.

## Technical Overview

Since I'm a Kubernetes Engineer, the solution will be a Kubernetes cluster with all services beeing containerized. As Kubernetes distribution I'm using K3s as it has batteries included (which helps to reduce maintenance in my opinion) and it's lightweight, saving costly compute.

The why section said it shall be a central solution. This has to be understood in more of a symbolic way. It's one cluster managed with the same set of tools. But in terms of phyiscal location the cluster is spread over a good number of places. This is done to save money and spin up compute wherever it's currently cheap. To make this happen, I base the cluster-networking on [Tailscale](https://tailscale.com), so that nodes can be in any network anywhere on the world. This is a dramatic decision as it makes the network a Single-Point-Of-Failure (SPOF), which we tolerate to achieve higher goals. Currently I got nodes on [Infomaniak](https://infomaniak.com), [Hetzner](https://hetzner.de) and some at home.

## Technical deep dive

Some topics need further discussion.

### Naming

A word about naming: naming is hard and complex, therefore we have stupid names.

Axiom is the entire cluster, because that's the big spaceship out of the disney movie "WALL-E" (2007).

The masters / servers are nummbered with the prefix `M-O` for the very clever and observant vacuum cleaner robot aboard axiom.

The workers / agents are nummbered with the prefix `WALL-A` for the big clunky robots that compress garbage to cubes aboard axiom.

### Automation

It's not necessary to automate this solution, but we do out of two reasons:
- reproducable in case of a desaster
- automatic documentation of what has been done (not necessairly for someone to understand the thing, but for me as a reference)

I decided against automating the Infrastructre with [Terraform](https://www.terraform.io/) after some initial tests since Terraform is limited in terms of configuring the cluster & addons and the infrastructure is only a small part of the setup that won't change often. So we use [Ansible](https://www.ansible.com/) as our main automation tool and later on GitOps with [Argo CD](https://argo-cd.readthedocs.io/en/stable/).

### DNS

We use the dns zone `axiom.technat.ch` for everything related to the cluster (e.g APIs, nodes, infrastructure services...). The zone is of course registered by Infomaniak and maintained in their Public Cloud with Openstack Designate. All records will be public regardless whether they contain a private or public IP.

Due to how the zone is hosted, it can be accessed by [external-dns](https://github.com/kubernetes-sigs/external-dns) to automatically set DNS records for us.

Services exposed externally on the cluster may of course use other DNS zones as well, but then without automation (e.g no external-dns).

### Backup

The storage for all backups shall be an S3 bucket somewhere in Infomaniak.

This means either an Openstack Swift container or Infomaniak Swiss Backup solution.

### CNI

To drive the pod/service networking I use [Cilium](https://cilium.io) with overlay networking. This is mainly to keep my knowledge around Cilium up to date, for an easy/maintenance-free setup the built-in CNI [Flannel](https://github.com/flannel-io/flannel) would of course be better.

If for any reason we switch CNI in the future, these things are important:
- Implementation of Network Policies and preferably also a custom implementation with more features
- some sort of visibility into the network flow logs (either via CLI or WebUI)
- it must be able to deal with multiple interfaces on the nodes (e.g because the nodes use `tailscale0` and not their primary interface for communication)

### Secrets

There is only one place for secrets: Akeyless SaaS Platform.

But there might be some tokens to access akeyless in various places, if they cannot use some nicer auth method (like OAuth2)

[Akeyless](https://akeyless.io) is a SaaS Solution for managing secrets and integrates well with Kubernetes. You can find the Console here: [Link](https://console.akeyless.io) (Login with Github)

### TLS

Kubernetes highly depends on TLS to secure internal communication. So we need a good management of CAs. To start with, there will be two CAs:

- the one k3s automatically generates and manages during the installation -> we don't touch nor export this one
- an `axiom CA` we create in akeyless for everything else that requires TLS

They have no relation to each other nor do they trust each other.

### Exposing services

Internal services must be accessible on a subdomain of `axiom.technat.ch` within the tailnet, external services may be accessible on any domain and IP.

One possible solution would be a custom tailscale funnel proxy, the other one would be leveraging servicelb to expose `443` and `80` on certain worker nodes which have a public IP. This would require multiple IPs for the same DNS record.

### Operating systems

We only use Linux for our task. Currently the playbook is focused on Ubuntu 22.04, but that could change in the future. Since we don't manage Infrastructure declaritively, here are the minimal requirements you need to ensure when you provision Infrastructure:
- console access via provider's website/portal must be possible as root (password saved in akeyless)
- tailscale must be installed and logged in (ssh, disabled key expiry + correct tagsa), thus enabling tailscale SSH access
- we don't care if nodes have a public IPv4, IPv6 or just a private IP, as long as they can join our tailnet we should be able to use it (maybe not for incoming traffic but for everything else)
- if you use any firewall on your nodes or within the cloud providers network, you must ensure all egress traffic is allowed, ICMP is allowed and tcp 80/443 are open for nodes that have a public IP address (all rules for v4 and v6 if applicable)

### Level of services

The services are categorized into different levels that all represent an Argo CD sync wave and a priority class in K8s.

We have:
- -5/2000001000: node-critical service
- -4/2000000000: cluster-critical service
- -3/1000000000: core service
- -2/100000000: almost core service 
- -1/10000000: regular infra service 
- 0/1000000: workload


