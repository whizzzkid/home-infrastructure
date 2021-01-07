# Home Infrastructure

Modernize your home infrastructure, like a pro!

*Please read through the entire documentation before starting.*

## Capabilities

- Run local infrastructure in docker containers for easier upgrades and robustness.
- Add home automation and network wide ad-block.
- Expose local services externally in a secure way.
- Authentication using Google OAuth.
- ELK stack for log monitoring and search.
- Automatic SSL generation using LetsEncrypt Acme.
- Run hassio addons in a supervised environment.
- Access smart home features from anywhere in the world.
- Add plenty of other services from https://www.reddit.com/r/selfhosted fast and secure.

## Recommended Hardware:

- Raspberry Pi 4b, 4GB Ram or better.
- SSD for boot, Samsung EVO 860 or similar. MicroSD will wear out quickly!
- Optional cooling/case.
- OC may work nice too!

![Hardware](https://i.imgur.com/5EJ8jNx.jpg)

## High Level Architecture

![High Level Architecture](https://i.imgur.com/ZL8WrxV.png)

## Checklist

- [x] This setup assumes, you already are in possession of a domain name which will allow you to
      access services in your infrastructure remotely. This could be a free domain as well.
- [x] Also, you are using Cloudflare as your CDN/DNS provider for the given domain, i.e. your domain
      points to Cloudflare's nameservers.
- [x] Have a router capable of setting up NAT server/routes.
- [x] Also, you are using [DietPi](https://dietpi.com/) as your OS and are logged in as root.
      Hence, all commands are being run as root. I am using `64-bit ArmV8-Buster` image without any
      issues. It should work just as well with any other debian based distro.
- [x] You are able to SSH into the RPi or use a keyboard and screen.
- [x] Setup `DietPi` to use a static IP (say, 192.168.0.10)
- [x] You have working knowledge of an editor in the terminal, like `nano` or `vi`
- [x] This setup also assumes you installed `docker`, you can use `dietpi-software` to install
      `Docker`.
- [x] You also installed `git`, you can use `dietpi-software` to install `git` too.


## Setup Instructions

If the above checklist is complete, we can now go on with the next steps:

- Fork this repo, this will be needed if you plan to save your own configs.
- Clone the repo you just forked:
    ```bash
    git clone https://github.com/<user_name>/home-infrastructure.git && cd home-infrastructure
    ```
- We need `docker-compose` and all the related dependencies which can be installed:
    ```bash
    ./setup.sh
    ```
- Populate the `.env` (this stores all your secrets, hence never committed).
    ```bash
    nano .env
    ```
- Fill out all the details:
    ```bash
    # Global
    LOG_LEVEL=ERROR         # Could be DEBUG, INFO, ERROR, NONE
    TZ='America/Edmonton'   # Timezone
    PGID=1000               # You don't need to touch this
    PUID=1000               # You don't need to touch this

    # Cloudflare
    CF_KEY=                 # Cloudflare token with zone edit permissions for the domain you own.
    CF_EMAIL=               # Cloudflare email id
    CF_ZONE=                # Cloudflare zone id for the domain

    # Domains
    BASE_URL=               # domain.tld
    SUBDOMAIN=              # home [or could be anything where your services should show up]
    HOME_URL=                 # home.domain.tld [or whatever you used in previous step]

    # Github PAT for docker package registry.
    GH_PAT=                 # Github personal access token with `read:packages` permission.

    # Auth/TFA
    SECRET_SALT=            # Random string, make it 64bytes long.
    GOOGLE_CLIENT_ID=       # Register your project on Google console and get this.
    GOOGLE_CLIENT_SECRET=   # Ditto
    WHITELISTED='user1@gmail.com,user2@domain.tld'
    AUTH_LOGIN_TOKEN_EXPIRY=2592000
    ```

- Once everything is filled in, just start:
    ```bash
    ./run.sh -v
    ```

- If something does not look right, kill all containers and force rebuild:
    ```bash
    ./run.sh -kv
    ```

## Credentials

- Google specific credentials for log-in, [read this](https://github.com/thomseddon/traefik-forward-auth#provider-setup).
- Cloudflare specific credentials for DNS updates, [read this](https://github.com/oznu/docker-cloudflare-ddns#creating-a-cloudflare-api-token).

## URL Structure

All services are now behind a reverse proxy, this script would setup six services for you.

1. `home.domain.tld` this is your dashboard, behind Google Auth, you can go in add links to your
   services however you like them (this has to be done manually)
2. `pihole.home.domain.tld` this is the pihole web-interface to manage your adblocker.
3. `hass.home.domain.tld` this is your home automation hub.
4. `portainer.home.domain.tld` you can manage your containers here.
5. `traefik.home.domain.tld` status of your reverse proxy.
6. `kibana.home.domain.tld` all your container logs in one place, searchable.

## Network Configuration:

- Go to your router settings page, add a NAT route:
    ```bash
    Service Type: HTTPS
    External Port: 443
    Internal IP: 192.168.0.10 (RPi IP address)
    Internal Port: 443
    Protocol: TCP
    ```

- In your cloudflare settings panel, change SSL config to `Full SSL`

## Starting Up

Once the server is up and running, all of the services will boot up and create their own configs.
I would recommend reading through each of their documentation to understand their capabilities.

- **HASS:** will load default configs, now you can navigate to integrations and setup all your local
  hardware
- **PiHole:** will load default configs, you can setup your favorite block-lists and setup DHCP as
  well. The service is configured to load DNS-over-HTTPS by default using cloudflared.
- **Kibana:** You will need to create a new index pattern to view your dashboard. The index patter
  would be `logstash-*`
- **Heimdall:** You can upload custom icons and setup links to your services.

## Saving Configurations permanently

Most of the services will be storing data in their own docker volumes. But if you decide
you need to save configurations manually, you can create:

    mkdir -p <app_name-config>

and then edit `docker-compose.yaml` in the `volumes:` section for the app replace `app_name-data`
with `./app_name-config`. Delete the entry from the docker volumes section on the top.

>**Note:** Make sure you are not committing secrets in your public repo.

## Removing Double Authentication

Since your reverse proxy is protecting all your endpoints, you might want to remove additional
inbuilt authentication settings:

1. **PiHole:** You need to send a command to change password to the container. Assuming pihole is
   alread up and running:
   ```bash
   docker exec -it pihole pihole -a -p
   ```
   do not enter any value, just press return key, this will remove the [login screen for pihole](https://discourse.pi-hole.net/t/how-do-i-set-or-reset-the-web-interface-password/1328).

2. **HASS:** Once hass is up and running, it will populate files in your `hassio` folder. Edit the
   `hassio/configuration.yaml` file and add the following lines on the top:
    ```yaml
    homeassistant:
        auth_providers:
            - type: trusted_networks
            trusted_networks:
                - 172.18.0.0/24
            allow_bypass_login: true
    ```
    this bypasses auth for all requests coming via internal docker network. Since this will be going
    in via Traefik, this should not have additional authentication.

3. **Portainer:** Portainer does not support forward auth at [this point](https://github.com/portainer/portainer/issues/3893)

## Adding/Removing Services

You can add more services in the `docker-compose.yaml`. Or replace existing services with something
different, e.g. Replacing `pihole` with `adguard`:

- remove the `pihole` entry from `docker-compose.yaml`:
    ```yaml
    pihole:
        container_name: pihole
        ... more config
        ... everything.
    ```
- add the `adguard` config:
    ```yaml
    adguard:
        container_name: adguard
        image: adguard/adguardhome:latest
        depends_on:
        - traefik
        restart: unless-stopped
        volumes:
        - adguard_data:/opt/adguardhome/work
        - ./build/adguard:/opt/adguardhome/conf
        network_mode: host
        labels:
        - "traefik.enable=true"
        - "traefik.http.routers.adguard.rule=Host(`adguard.${HOME_URL}`)"
        - "traefik.http.routers.adguard.entrypoints=websecure"
        - "traefik.http.services.adguard.loadbalancer.server.port=3333"
        - "traefik.http.routers.adguard.service=adguard"
        - "traefik.http.routers.adguard.tls.certresolver=homeinfra"
        - "traefik.http.routers.adguard.middlewares=tfa"
        logging:
        driver: gelf
        options:
            gelf-address: udp://localhost:12201
            tag: "adguard"
    ```
- also create a volume in the global volumes section:
    ```yaml
        volumes:
            ...
            adguard_data:
                name: "adguard_data"
            ...
    ```
- kill and restart your containers:
    ``` bash
    ./run.sh -kv
    ```

## Disclaimer

All the services installed using this script are results of hardwork by their respective owners.
These carry their own licenses, rights and terms. The images used here are the last stable build
built for `AARCH64` architecture. You can change the versions as you may wish!

|        Service        |                           Project Page                            |                              Documentation                              | Image                                                                                                         |
|:--------------------: |:----------------------------------------------------------------: |:----------------------------------------------------------------------: |-------------------------------------------------------------------------------------------------------------- |
| Traefik               | https://github.com/traefik/traefik                                | https://doc.traefik.io/traefik/                                         | traefik:v2.3.6                                                                                                |
| TFA                   | https://github.com/thomseddon/traefik-forward-auth                | https://github.com/thomseddon/traefik-forward-auth                      | npawelek/traefik-forward-auth:latest                                                                          |
| Portainer             | https://github.com/portainer/portainer                            | https://documentation.portainer.io/                                     | portainer/portainer-ce:2.0.1                                                                                  |
| Cloudflared           | https://github.com/cloudflare/cloudflared                         | https://developers.cloudflare.com/argo-tunnel/                          | crazymax/cloudflared:latest                                                                                   |
| Cloudflare-Companion  | https://github.com/tiredofit/docker-traefik-cloudflare-companion  | https://github.com/tiredofit/docker-traefik-cloudflare-companion        | docker.pkg.github.com/jwillmer/docker-traefik-cloudflare-companion/docker-traefik-cloudflare-companion:6.1.2  |
| Cloudflare-DDNS       | https://github.com/oznu/docker-cloudflare-ddns                    | https://github.com/oznu/docker-cloudflare-ddns                          | oznu/cloudflare-ddns:latest                                                                                   |
| Heimdall              | https://github.com/linuxserver/Heimdall                           | https://heimdall.site/                                                  | ghcr.io/linuxserver/heimdall                                                                                  |
| PiHole                | https://github.com/pi-hole/pi-hole                                | https://docs.pi-hole.net/                                               | pihole/pihole:latest                                                                                          |
| Home Assistant        | https://github.com/home-assistant/core                            | https://www.home-assistant.io/docs/                                     | homeassistant/raspberrypi4-64-homeassistant:stable                                                            |
| Elasticsearch         | https://github.com/elastic/elasticsearch                          | https://www.elastic.co/guide/en/elasticsearch/reference/7.x/index.html  | elasticsearch:7.9.3                                                                                           |
| Logstash              | https://github.com/elastic/logstash                               | https://www.elastic.co/guide/en/logstash/7.x/index.html                 | raquette/logstash-oss:7.9.3                                                                                   |
| Kibana                | https://github.com/elastic/kibana                                 | https://www.elastic.co/guide/en/kibana/7.x/index.html                   | raquette/kibana-oss:7.9.3                                                                                     |

## License
MIT

