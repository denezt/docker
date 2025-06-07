
# Jenkins with SSL Setup

### This guide describes how to build and run Jenkins with SSL enabled, using nginx as a reverse proxy. The configuration ensures secure HTTPS access to Jenkins.

## Directory Structure

``` wasm
jenkins-ssl/
├── Dockerfile
├── jenkins.crt
├── jenkins.key
└── nginx.conf
````

- `Dockerfile`: Builds a Jenkins image with nginx configured for SSL termination.
- `jenkins.crt` and `jenkins.key`: Your SSL certificate and private key.
- `nginx.conf`: nginx configuration file for SSL and proxying to Jenkins.

## Prerequisites

- Docker installed on your system.
- Valid SSL certificate (`jenkins.crt`) and private key (`jenkins.key`). For production, use a certificate signed by a trusted CA.

## Setup Instructions

1. **Prepare SSL Certificates**

   Place your `jenkins.crt` and `jenkins.key` files in the project directory.

2. **Build the Docker Image**

   ``` sh
   docker build -t jenkins-ssl .
   ````

3. **Run the Jenkins Container**

   ```sh
   docker run -d -p 443:443 --name jenkins-ssl jenkins-ssl
   ```

4. **Access Jenkins**

   Open your browser and navigate to:

   ```
   https://<your-server-ip>/
   ```

   > The first time you access Jenkins, you will need the initial admin password. Run:
   >
   > ```sh
   > docker exec jenkins-ssl cat /var/jenkins_home/secrets/initialAdminPassword
   > ```

5. **nginx Configuration**

   The provided `nginx.conf` is already configured to:

   * Listen on port 443 (HTTPS)
   * Use the provided SSL cert and key
   * Forward requests to Jenkins running on port 8080

   Adjust the `server_name` directive for your domain as needed.


## Developer Notes

* For production, you may wish to separate nginx and Jenkins into different containers and use Docker Compose or Kubernetes.
* The default Jenkins home is `/var/jenkins_home`. All configuration, plugins, and job data reside here.

---

## Example `nginx.conf`

```nginx
server {
    listen 443 ssl;
    server_name _;

    ssl_certificate     /etc/ssl/certs/jenkins.crt;
    ssl_certificate_key /etc/ssl/private/jenkins.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```


### References

- For more information about Jenkins, visit the [Jenkins official documentation](https://www.jenkins.io/doc/).

- [NGINX](https://nginx.org) ("engine x") is an HTTP web server, reverse proxy, content cache, load balancer, TCP/UDP proxy server, and mail proxy server.
