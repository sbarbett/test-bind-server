# test-bind-server

Just a simple script that spins up a BIND and nginx server on a newly provisioned server. For testing purposes.

## Usage

```
git clone https://github.com/sbarbett/test-bind-server
cd test-bind-server
chmod +x setup.sh
sudo ./setup.sh {{ip_address}} > setup.log 2>&1
```

This will pipe the output into a log file, in case troubleshooting is necessary.
