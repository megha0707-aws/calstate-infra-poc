# Namespace network policies



# Grouper namespace network policies
#
# These policies implement the baseline microsegmentation posture for Grouper:
# - Deny all ingress and egress by default.
# - Allow only DNS egress to CoreDNS so pods can resolve Kubernetes services.
#
# Application-specific allow policies must be added later for known flows such
# as ingress-to-UI, UI-to-WS, WS-to-daemon, and Grouper-to-PostgreSQL.

# Stage: default deny for all Grouper pods.
# Empty pod_selector means "all pods in the namespace."
# policy_types = ["Ingress", "Egress"] means both inbound and outbound traffic
# are denied unless another NetworkPolicy explicitly allows the flow.
resource "kubernetes_network_policy_v1" "stage_grouper_default_deny" {
  provider = kubernetes.stage

  metadata {
    name      = "default-deny"
    namespace = kubernetes_namespace_v1.stage_grouper.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# Stage: allow Grouper pods to query CoreDNS.
# This is required because the default-deny policy blocks all egress, including
# DNS. Without this policy, pods may fail to resolve service names.
resource "kubernetes_network_policy_v1" "stage_grouper_allow_dns_egress" {
  provider = kubernetes.stage

  metadata {
    name      = "allow-dns-egress"
    namespace = kubernetes_namespace_v1.stage_grouper.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      # Select CoreDNS pods in the kube-system namespace.
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }

        pod_selector {
          match_labels = {
            "k8s-app" = "kube-dns"
          }
        }
      }

      # Allow DNS over UDP and TCP. UDP is the common path; TCP is needed for
      # larger responses and retries.
      ports {
        protocol = "UDP"
        port     = "53"
      }

      ports {
        protocol = "TCP"
        port     = "53"
      }
    }
  }
}

# Prod: default deny for all Grouper pods.
# Mirrors the stage baseline so both environments enforce the same posture.
resource "kubernetes_network_policy_v1" "prod_grouper_default_deny" {
  provider = kubernetes.prod

  metadata {
    name      = "default-deny"
    namespace = kubernetes_namespace_v1.prod_grouper.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# Prod: allow Grouper pods to query CoreDNS.
# Mirrors the stage DNS exception.
resource "kubernetes_network_policy_v1" "prod_grouper_allow_dns_egress" {
  provider = kubernetes.prod

  metadata {
    name      = "allow-dns-egress"
    namespace = kubernetes_namespace_v1.prod_grouper.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      # Select CoreDNS pods in the kube-system namespace.
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }

        pod_selector {
          match_labels = {
            "k8s-app" = "kube-dns"
          }
        }
      }

      # Allow DNS over UDP and TCP.
      ports {
        protocol = "UDP"
        port     = "53"
      }

      ports {
        protocol = "TCP"
        port     = "53"
      }
    }
  }
}
