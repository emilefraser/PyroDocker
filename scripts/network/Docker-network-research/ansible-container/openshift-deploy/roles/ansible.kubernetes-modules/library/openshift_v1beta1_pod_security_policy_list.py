#!/usr/bin/env python

from ansible.module_utils.openshift_common import OpenShiftAnsibleModule, OpenShiftAnsibleException

DOCUMENTATION = '''
module: openshift_v1beta1_pod_security_policy_list
short_description: OpenShift PodSecurityPolicyList
description:
- Retrieve a list of pod_security_policys. List operations provide a snapshot read
  of the underlying objects, returning a resource_version representing a consistent
  version of the listed objects.
version_added: 2.3.0
author: OpenShift (@openshift)
options:
  api_key:
    description:
    - Token used to connect to the API.
  cert_file:
    description:
    - Path to a certificate used to authenticate with the API.
    type: path
  context:
    description:
    - The name of a context found in the Kubernetes config file.
  debug:
    description:
    - Enable debug output from the OpenShift helper. Logging info is written to KubeObjHelper.log
    default: false
    type: bool
  force:
    description:
    - If set to C(True), and I(state) is C(present), an existing object will updated,
      and lists will be replaced, rather than merged.
    default: false
    type: bool
  host:
    description:
    - Provide a URL for acessing the Kubernetes API.
  key_file:
    description:
    - Path to a key file used to authenticate with the API.
    type: path
  kubeconfig:
    description:
    - Path to an existing Kubernetes config file. If not provided, and no other connection
      options are provided, the openshift client will attempt to load the default
      configuration file from I(~/.kube/config.json).
    type: path
  namespace:
    description:
    - Namespaces provide a scope for names. Names of resources need to be unique within
      a namespace, but not across namespaces. Provide the namespace for the object.
  password:
    description:
    - Provide a password for connecting to the API. Use in conjunction with I(username).
  ssl_ca_cert:
    description:
    - Path to a CA certificate used to authenticate with the API.
    type: path
  username:
    description:
    - Provide a username for connecting to the API.
  verify_ssl:
    description:
    - Whether or not to verify the API server's SSL certificates.
    type: bool
requirements:
- openshift == 1.0.0-snapshot
'''

EXAMPLES = '''
'''

RETURN = '''
api_version:
  type: string
  description: Requested API version
pod_security_policy_list:
  type: complex
  returned: on success
  contains:
    api_version:
      description:
      - APIVersion defines the versioned schema of this representation of an object.
        Servers should convert recognized schemas to the latest internal value, and
        may reject unrecognized values.
      type: str
    items:
      description:
      - Items is a list of schema objects.
      type: list
      contains:
        api_version:
          description:
          - APIVersion defines the versioned schema of this representation of an object.
            Servers should convert recognized schemas to the latest internal value,
            and may reject unrecognized values.
          type: str
        kind:
          description:
          - Kind is a string value representing the REST resource this object represents.
            Servers may infer this from the endpoint the client submits requests to.
            Cannot be updated. In CamelCase.
          type: str
        metadata:
          description:
          - Standard object's metadata.
          type: complex
          contains:
            annotations:
              description:
              - Annotations is an unstructured key value map stored with a resource
                that may be set by external tools to store and retrieve arbitrary
                metadata. They are not queryable and should be preserved when modifying
                objects.
              type: complex
              contains: str, str
            cluster_name:
              description:
              - The name of the cluster which the object belongs to. This is used
                to distinguish resources with same name and namespace in different
                clusters. This field is not set anywhere right now and apiserver is
                going to ignore it if set in create or update request.
              type: str
            creation_timestamp:
              description:
              - CreationTimestamp is a timestamp representing the server time when
                this object was created. It is not guaranteed to be set in happens-before
                order across separate operations. Clients may not set this value.
                It is represented in RFC3339 form and is in UTC. Populated by the
                system. Read-only. Null for lists.
              type: complex
              contains: {}
            deletion_grace_period_seconds:
              description:
              - Number of seconds allowed for this object to gracefully terminate
                before it will be removed from the system. Only set when deletionTimestamp
                is also set. May only be shortened. Read-only.
              type: int
            deletion_timestamp:
              description:
              - DeletionTimestamp is RFC 3339 date and time at which this resource
                will be deleted. This field is set by the server when a graceful deletion
                is requested by the user, and is not directly settable by a client.
                The resource is expected to be deleted (no longer visible from resource
                lists, and not reachable by name) after the time in this field. Once
                set, this value may not be unset or be set further into the future,
                although it may be shortened or the resource may be deleted prior
                to this time. For example, a user may request that a pod is deleted
                in 30 seconds. The Kubelet will react by sending a graceful termination
                signal to the containers in the pod. After that 30 seconds, the Kubelet
                will send a hard termination signal (SIGKILL) to the container and
                after cleanup, remove the pod from the API. In the presence of network
                partitions, this object may still exist after this timestamp, until
                an administrator or automated process can determine the resource is
                fully terminated. If not set, graceful deletion of the object has
                not been requested. Populated by the system when a graceful deletion
                is requested. Read-only.
              type: complex
              contains: {}
            finalizers:
              description:
              - Must be empty before the object is deleted from the registry. Each
                entry is an identifier for the responsible component that will remove
                the entry from the list. If the deletionTimestamp of the object is
                non-nil, entries in this list can only be removed.
              type: list
              contains: str
            generate_name:
              description:
              - GenerateName is an optional prefix, used by the server, to generate
                a unique name ONLY IF the Name field has not been provided. If this
                field is used, the name returned to the client will be different than
                the name passed. This value will also be combined with a unique suffix.
                The provided value has the same validation rules as the Name field,
                and may be truncated by the length of the suffix required to make
                the value unique on the server. If this field is specified and the
                generated name exists, the server will NOT return a 409 - instead,
                it will either return 201 Created or 500 with Reason ServerTimeout
                indicating a unique name could not be found in the time allotted,
                and the client should retry (optionally after the time indicated in
                the Retry-After header). Applied only if Name is not specified.
              type: str
            generation:
              description:
              - A sequence number representing a specific generation of the desired
                state. Populated by the system. Read-only.
              type: int
            labels:
              description:
              - Map of string keys and values that can be used to organize and categorize
                (scope and select) objects. May match selectors of replication controllers
                and services.
              type: complex
              contains: str, str
            name:
              description:
              - Name must be unique within a namespace. Is required when creating
                resources, although some resources may allow a client to request the
                generation of an appropriate name automatically. Name is primarily
                intended for creation idempotence and configuration definition. Cannot
                be updated.
              type: str
            namespace:
              description:
              - Namespace defines the space within each name must be unique. An empty
                namespace is equivalent to the "default" namespace, but "default"
                is the canonical representation. Not all objects are required to be
                scoped to a namespace - the value of this field for those objects
                will be empty. Must be a DNS_LABEL. Cannot be updated.
              type: str
            owner_references:
              description:
              - List of objects depended by this object. If ALL objects in the list
                have been deleted, this object will be garbage collected. If this
                object is managed by a controller, then an entry in this list will
                point to this controller, with the controller field set to true. There
                cannot be more than one managing controller.
              type: list
              contains:
                api_version:
                  description:
                  - API version of the referent.
                  type: str
                controller:
                  description:
                  - If true, this reference points to the managing controller.
                  type: bool
                kind:
                  description:
                  - Kind of the referent.
                  type: str
                name:
                  description:
                  - Name of the referent.
                  type: str
                uid:
                  description:
                  - UID of the referent.
                  type: str
            resource_version:
              description:
              - An opaque value that represents the internal version of this object
                that can be used by clients to determine when objects have changed.
                May be used for optimistic concurrency, change detection, and the
                watch operation on a resource or set of resources. Clients must treat
                these values as opaque and passed unmodified back to the server. They
                may only be valid for a particular resource or set of resources. Populated
                by the system. Read-only. Value must be treated as opaque by clients
                and .
              type: str
            self_link:
              description:
              - SelfLink is a URL representing this object. Populated by the system.
                Read-only.
              type: str
            uid:
              description:
              - UID is the unique in time and space value for this object. It is typically
                generated by the server on successful creation of a resource and is
                not allowed to change on PUT operations. Populated by the system.
                Read-only.
              type: str
        spec:
          description:
          - spec defines the policy enforced.
          type: complex
          contains:
            allowed_capabilities:
              description:
              - AllowedCapabilities is a list of capabilities that can be requested
                to add to the container. Capabilities in this field may be added at
                the pod author's discretion. You must not list a capability in both
                AllowedCapabilities and RequiredDropCapabilities.
              type: list
              contains: str
            default_add_capabilities:
              description:
              - DefaultAddCapabilities is the default set of capabilities that will
                be added to the container unless the pod spec specifically drops the
                capability. You may not list a capabiility in both DefaultAddCapabilities
                and RequiredDropCapabilities.
              type: list
              contains: str
            fs_group:
              description:
              - FSGroup is the strategy that will dictate what fs group is used by
                the SecurityContext.
              type: complex
              contains:
                ranges:
                  description:
                  - Ranges are the allowed ranges of fs groups. If you would like
                    to force a single fs group then supply a single range with the
                    same start and end.
                  type: list
                  contains:
                    max:
                      description:
                      - Max is the end of the range, inclusive.
                      type: int
                    min:
                      description:
                      - Min is the start of the range, inclusive.
                      type: int
                rule:
                  description:
                  - Rule is the strategy that will dictate what FSGroup is used in
                    the SecurityContext.
                  type: str
            host_ipc:
              description:
              - hostIPC determines if the policy allows the use of HostIPC in the
                pod spec.
              type: bool
            host_network:
              description:
              - hostNetwork determines if the policy allows the use of HostNetwork
                in the pod spec.
              type: bool
            host_pid:
              description:
              - hostPID determines if the policy allows the use of HostPID in the
                pod spec.
              type: bool
            host_ports:
              description:
              - hostPorts determines which host port ranges are allowed to be exposed.
              type: list
              contains:
                max:
                  description:
                  - max is the end of the range, inclusive.
                  type: int
                min:
                  description:
                  - min is the start of the range, inclusive.
                  type: int
            privileged:
              description:
              - privileged determines if a pod can request to be run as privileged.
              type: bool
            read_only_root_filesystem:
              description:
              - ReadOnlyRootFilesystem when set to true will force containers to run
                with a read only root file system. If the container specifically requests
                to run with a non-read only root file system the PSP should deny the
                pod. If set to false the container may run with a read only root file
                system if it wishes but it will not be forced to.
              type: bool
            required_drop_capabilities:
              description:
              - RequiredDropCapabilities are the capabilities that will be dropped
                from the container. These are required to be dropped and cannot be
                added.
              type: list
              contains: str
            run_as_user:
              description:
              - runAsUser is the strategy that will dictate the allowable RunAsUser
                values that may be set.
              type: complex
              contains:
                ranges:
                  description:
                  - Ranges are the allowed ranges of uids that may be used.
                  type: list
                  contains:
                    max:
                      description:
                      - Max is the end of the range, inclusive.
                      type: int
                    min:
                      description:
                      - Min is the start of the range, inclusive.
                      type: int
                rule:
                  description:
                  - Rule is the strategy that will dictate the allowable RunAsUser
                    values that may be set.
                  type: str
            se_linux:
              description:
              - seLinux is the strategy that will dictate the allowable labels that
                may be set.
              type: complex
              contains:
                rule:
                  description:
                  - type is the strategy that will dictate the allowable labels that
                    may be set.
                  type: str
                se_linux_options:
                  description:
                  - seLinuxOptions required to run as; required for MustRunAs
                  type: complex
                  contains:
                    level:
                      description:
                      - Level is SELinux level label that applies to the container.
                      type: str
                    role:
                      description:
                      - Role is a SELinux role label that applies to the container.
                      type: str
                    type:
                      description:
                      - Type is a SELinux type label that applies to the container.
                      type: str
                    user:
                      description:
                      - User is a SELinux user label that applies to the container.
                      type: str
            supplemental_groups:
              description:
              - SupplementalGroups is the strategy that will dictate what supplemental
                groups are used by the SecurityContext.
              type: complex
              contains:
                ranges:
                  description:
                  - Ranges are the allowed ranges of supplemental groups. If you would
                    like to force a single supplemental group then supply a single
                    range with the same start and end.
                  type: list
                  contains:
                    max:
                      description:
                      - Max is the end of the range, inclusive.
                      type: int
                    min:
                      description:
                      - Min is the start of the range, inclusive.
                      type: int
                rule:
                  description:
                  - Rule is the strategy that will dictate what supplemental groups
                    is used in the SecurityContext.
                  type: str
            volumes:
              description:
              - volumes is a white list of allowed volume plugins. Empty indicates
                that all plugins may be used.
              type: list
              contains: str
    kind:
      description:
      - Kind is a string value representing the REST resource this object represents.
        Servers may infer this from the endpoint the client submits requests to. Cannot
        be updated. In CamelCase.
      type: str
    metadata:
      description:
      - Standard list metadata.
      type: complex
      contains:
        resource_version:
          description:
          - String that identifies the server's internal version of this object that
            can be used by clients to determine when objects have changed. Value must
            be treated as opaque by clients and passed unmodified back to the server.
            Populated by the system. Read-only.
          type: str
        self_link:
          description:
          - SelfLink is a URL representing this object. Populated by the system. Read-only.
          type: str
'''


def main():
    try:
        module = OpenShiftAnsibleModule('pod_security_policy_list', 'V1beta1')
    except OpenShiftAnsibleException as exc:
        # The helper failed to init, so there is no module object. All we can do is raise the error.
        raise Exception(exc.message)

    try:
        module.execute_module()
    except OpenShiftAnsibleException as exc:
        module.fail_json(msg="Module failed!", error=str(exc))


if __name__ == '__main__':
    main()
