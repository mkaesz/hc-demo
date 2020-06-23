# HashiCorp Onboarding Phase Demo
I've built this demo over the first couple of weeks during my onboarding phase at HashiCorp.

## It includes
  * Fully TLS encrypted Consul cluster (3 nodes by default, configurable).
  * Fully TLS encrypted Vault cluster with Consul as storage backend (2 nodes by default, configurable).
  * Fully TLS encrypted Nomad cluster:
    - Nomad cluster is built by reading cluster peers from Consul.
    - Consul configured for service registration and discovery.
    - Vault configured for secrests lookup.
    - Nomad workers read cluster information from Consul.
  * A bastion host that has CLIs configured for Vault, Nomad and consul.
  * The VMs are based on a custom build fedora 33 installation. Packer is used to build the libvirt image.
    The actual installation and configuration happens via a kickstart file.
  * Terraform is being used to create the VMs based on the packer output. All VMs are configured via cloud init. The binaries 
    of all the products are installed as part of the packer kickstart.
  * The demo shows the integration between Consul, Vault and Nomad.
      - It deploys a Postgres database with data included on Nomad.
      - It deploys a web service (default: two instances) that connects to that database by looking up the service via Consul 
         on Nomad.
      - It deploys a HAproxy load balancer that looks up the web services and configures them for load balancing. Lookup happens 
         again via Consul DNS.
      - The web service gets access to the database by requesting credentials from Vault via the database secret engine and 
         according policies.

## Remarks
  * I used libvirt, qemu and KVM.
  * I had a DNS server running outside of this demo that all VMs get registered with as part of their provisioning. 
    The DNS is CoreDNS with a ETCD backend.
  * All VMs have a dnsmasq running that have the CoreDNS server configured as upstream. Consul itself is configured to response 
    to all .consul domains.
  * My public key is configured on all VMs. I could therefore ssh into all VMs.
  * Enterprise binaries are included. The HashiCorp licenses for Vault and Consul are not included in this repo or the VMs. They were located on my 
    desktop.
  * Demo uses Docker as runtime with a custom Docker network/bridge that gets created as part of cloudinit. The bridge is called "nomad". The demo uses that network to attach the constainer to. Reason is that the default bridge doesn't use the DNS from the underlying host.
  
## Initialization of Vault and Nomad
On the bastion host:

```
cd ~

# Initialize nomad
bash nomad-bootstrap.sh

#Initialize vault 
bash vault-bootstrap.sh
```

## Run the demo
On the bastion host:

``` 
cd ~/demo/vault-nomad-demo

# Create the database
nomad run postgres-nomad-demo.nomad

# Enable the database engine
vault secrets enable database

# Configure the connection
vault write database/config/postgresql @connection.json

# Configure the command to be executed when requesting credentials
vault write database/roles/accessdb db_name=postgresql \
	creation_statements=@accessdb.sql default_ttl=1h max_ttl=24h

# Test everything manually
vault read database/creds/accessdb

# Write the policy that nomad uses to request credentials
vault policy write access-tables access-tables-policy.hcl

# Run the web service
nomad run nomad-vault-demo.nomad

# Run the load balancer
nomad run haproxy.nomad

# Get the endpoint of the load balancer
nomad status haproxy

# Get the allocation ID from the last entry in the alloc table
nomad alloc status <ID>

# curl the IP with the ending 8080
curl <IP>:8008/names

You should see the following:

mkaesz@bastion$ curl 192.168.122.27:8080/names
<!DOCTYPE html>
<html>
<body>

<h1> Welcome! </h1>
<h2> If everything worked correctly, you should be able to see a list of names below </h2>

<hr>


<h4> John Doe </h4>

<h4> Peter Parker </h4>

<h4> Clifford Roosevelt </h4>

<h4> Bruce Wayne </h4>

<h4> Steven Clark </h4>

<h4> Mary Jane </h4>


</body>
<html>
```  
  
## ToDos
  * Remove my personal public key from all VMs and make the bastion host the single point to access the nodes.
  * Move to Nomad Enterprise.
  * Include Terraform Enterprise.
  * Include Kubernetes and integrate it with Consul and Vault.
  * Add config and demo for Consul Service Mesh.
