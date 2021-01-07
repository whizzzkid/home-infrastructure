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
    BS_URL=                 # home.domain.tld [or whatever you used in previous step]

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
