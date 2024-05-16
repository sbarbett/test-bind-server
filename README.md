# test-bind-server

Just a simple script that spins up a BIND and nginx server on a newly provisioned Ubuntu VM. For testing purposes.

## Bootstrap Usage

Clone the repository to your environment.

```
git clone https://github.com/sbarbett/test-bind-server
cd test-bind-server
```

The `config.json` file contains a few parameters that you should define:

* `domains` - A list of domains you want to add to your BIND server. It doesn't really matter what you choose. The server will give an authoritative response for these zones.
* `ip` - This is the IP address that the specified domains will resolve to. I intended for it to be the IP of the server itself, which is why a web server is also installed.
* `splash_text` - This is what will be displayed on the basic splash page at the index of the web server.

Once you've modified the configuration, make `setup.sh` executable and run it.

```
chmod +x setup.sh
sudo ./setup.sh > setup.log 2>&1
```

This will pipe the output into a log file, in case troubleshooting is necessary.

### Testing

You can query locally:

```
dig @localhost example1.com
curl http://localhost
```

### Security Note

This script opens up ports and installs services and is _not_ inteaded to be run on any sort of production environment. This is for demos on VMs that are discarded after use.

## Docker

Alternatively, you can run BIND and nginx inside a container using a loopback address on your local machine. I've included a Dockerfile for this purpose. The Dockerfile will use the same `config.json` parameters, just set the `ip` to `127.0.0.1`.

To build and run (from the test-bind-server directory where `Dockerfile` is located):

```
docker build -t test-bind-server .
docker run -d -p 53:53 -p 53:53/udp -p 80:80 --name mytestbindserver test-bind-server
```

## License

This project is licensed under the terms of the MIT license. See LICENSE.md for more details.