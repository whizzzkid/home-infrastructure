# home-infrastructure
Modernize your home infrastructure, be a pro!


# Checklist

- [x] This setup assumes, you already are in possession of a domain name which will allow you to
      access services in your infrastructure remotely. This could be a free domain as well.
- [x] Also, you are using Cloudflare as your CDN/DNS provider for the domain, i.e. your domain
      points to Cloudflare's nameservers.
- [x] Also, you are using [DietPi](https://dietpi.com/) and are logged in with root shell.
      So all commands are being run as root. I am using `64-bit ArmV8-Buster` image without any
      issues. It should work just as well with any other debian based distro.
- [x] You are able to SSH into the system or use a keyboard and screen.
- [x] You have working knowledge of an editor in the terminal, like `nano` or `vi`
- [x] This setup also assumes you installed `docker`, you can use `dietpi-software` to install
      `Docker`.
- [x] You can also install `git`, you can use `dietpi-software` to install `git`.


## Setup Instructions

If the above checklist is complete, we can now go on with the next steps:

- Clone this repo:
    ```bash
    git clone https://github.com/whizzzkid/home-infrastructure.git && cd home-Infrastructure
    ```
- We need `docker-compose` and all the related dependencies which can be installed:
    ```bash
    ./setup.sh
    ```
- Setup the `.env`
    ```bash
    cp env.example .env
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


## Structure.

All services are now behind a reverse proxy, this script would setup six services for you.

1. `home.domain.tld` this is your dashboard, behind Google Auth, you can go in add links to your
   services however you like them.
2. `pihole.home.domain.tld` this is the pihole web-interface to manage your adblocker.
3. `hass.home.domain.tld` this is your home automation hub.
4. `portainer.home.domain.tld` you can manage your containers here.
5. `traefik.home.domain.tld` status of your reverse proxy.
6. `kibana.home.domain.tld` all your container logs in one place, searchable.

## Saving Configurations

Most of the services will be storing their data in their own docker volumes. But if you decide
you need to save configurations manually, you can edit the `docker-compose.yaml`:
    ```bash
    mkdir -p <app_name-config>
    ```
and then in the `volumes:` section for the app replace `app_name-data` with `./app_name-config`.
Delete the entry from the top docker volumes section.

## Removing Double Authentication

Since your reverse proxy is protecting all your endpoints, you might want to remove additional
inbuilt authentication settings:

1. **PiHole:** You need to send a command to change password to the container. Assuming pihole is
   alread up and running:
   ```bash
   docker exec -it pihole pihole -a -p
   ```
   do not enter any value, just press return key, this will remove the [login screen for pihole](https://discourse.pi-hole.net/t/how-do-i-set-or-reset-the-web-interface-password/1328).

2. **HASS:** Once hass is up and running, it will populate files in your `hassio` folder. In the
   `configuration.yaml` add the following lines on the top:
    ```yaml
    homeassistant:
        auth_providers:
            - type: trusted_networks
            trusted_networks:
                - 172.18.0.0/24
            allow_bypass_login: true
    ```
    this bypasses auth for all requests coming via internal docker network. Since this will be
    going in via Traefik, this should not have additional authentication.

3. **Portainer:** Portainer does not support forward auth at [this point](https://github.com/portainer/portainer/issues/3893)

## Adding/Removing Services

You can add more services in the `docker-compose.yaml`. Or replace existing services with something
different.

1. Replacing `pihole` with `adguard`:
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
            # Admin
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

