# multitenant-s3
A Vagrantfile to spin up 4-node distributed [Minio](https://www.minio.io/) services on [Docker Swarm](https://docs.docker.com/engine/swarm/) cluster, and set [HAProxy](http://www.haproxy.org/) load-balancer.

## Installation
Clone the repository on your workstation with [Vagrant](https://www.vagrantup.com/) installed:
```
git clone https://github.com/rmin/multitenant-s3.git
cd multitenant-s3
```

And start the configuration process by executing:
```
vagrant up
```

## Usage
SSH into one of the Swarm nodes:
```
vagrant ssh us-east-1-1
```

#### Add Tenant
Run `tenant.sh` script to create a new tenant:
```
vagrant@us-east-1-1:~$ /vagrant/stack/tenant.sh tenant1

Generating secrets for the new tenant.
vjgf3a5u95cf10s6b47ra8aqh
ou6a5krhd830mpwfvgz2q6t8y
Creating service s3_tenant1_minio3-tenant1
Creating service s3_tenant1_minio4-tenant1
Creating service s3_tenant1_minio1-tenant1
Creating service s3_tenant1_minio2-tenant1
Adding proxy endpoint into hosts file (you need a proper DNS record for this).

Access key: B27QLEPPOGVSIFKKYCSL
Secret key: 8yRNGgXr8WZylfuK8Nd2vvouWhy6qBTBN0SKNSRt
Region: us-east-1
Endpoint-URL: tenant1.s3-us-east-1.example.com
```

#### Use the storage
For testing the service you can use `awscli` or `s3cmd` cli tool:
```
vagrant@us-east-1-1:~$ sudo apt install python-pip
vagrant@us-east-1-1:~$ sudo pip install s3cmd
vagrant@us-east-1-1:~$ cat > ~/.s3cfg << EOF
host_base = tenant1.s3-us-east-1.example.com
host_bucket = tenant1.s3-us-east-1.example.com
use_https = False
bucket_location = us-east-1
access_key = B27QLEPPOGVSIFKKYCSL
secret_key = 8yRNGgXr8WZylfuK8Nd2vvouWhy6qBTBN0SKNSRt
signature_v2 = False
EOF
```

Create a new bucket, and sync a local directory with the bucket:
```
vagrant@us-east-1-1:~$ s3cmd mb s3://bucket1
vagrant@us-east-1-1:~$ mkdir ./bucket1_dir
vagrant@us-east-1-1:~$ echo "testing!" > ./bucket1_dir/testfile
vagrant@us-east-1-1:~$ s3cmd sync ./bucket1_dir/ s3://bucket1
upload: './bucket1_dir/testfile' -> 's3://bucket1/testfile'  [1 of 1]
 9 of 9   100% in    0s   228.61 B/s  done
vagrant@us-east-1-1:~$ s3cmd ls s3://bucket1
2018-06-18 18:50         9   s3://bucket1/testfile
```

#### Delete Tenant
For deleting a tenant remove the Docker services on one of the Swarm nodes.
```
vagrant@us-east-1-1:~$ sudo docker stack rm s3_tenant1
```

Next you need to remove the tenant's data volumes on all swarm nodes. Run this once on each node:
```
sudo docker volume rm s3_tenant1_data
```

## License
MIT License

Copyright (c) 2018 @rmin
