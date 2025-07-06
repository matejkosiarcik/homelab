export const apps = {
    actualbudget: {
        title: 'ActualBudget',
        instances: [
            { url: 'https://actualbudget.matejhome.com', title: 'ActualBudget (private)' },
        ],
    },
    certbot: {
        title: 'Certbot',
        instances: [
            { url: 'https://certbot.matejhome.com', title: 'Certbot' },
        ],
    },
    changedetection: {
        title: 'Changedetection',
        instances: [
            { url: 'https://changedetection.matejhome.com', title: 'Changedetection' },
        ]
    },
    'docker-proxy': {
        title: 'Docker Proxy',
        instances: [
            { url: 'https://docker-cache-proxy-dockerhub.matejhome.com', title: 'DockerHub Proxy' },
        ],
    },
    dozzle: {
        title: 'Dozzle',
        instances: [
            { url: 'https://dozzle.matejhome.com', title: 'Dozzle server' },
        ],
    },
    'dozzle-agent': {
        title: 'Dozzle Agent',
        instances: [
            // { url: 'tcp://dozzle-agent-odroid-h3.matejhome.com', title: 'Dozzle Agent - Odroid H3' },
            { url: 'tcp://dozzle-agent-odroid-h4-ultra.matejhome.com', title: 'Dozzle Agent - Odroid H4 Ultra' },
            { url: 'tcp://dozzle-agent-raspberry-pi-4b-2g.matejhome.com', title: 'Dozzle Agent - Raspberry Pi 4B 2GB' },
            { url: 'tcp://dozzle-agent-raspberry-pi-4b-4g.matejhome.com', title: 'Dozzle Agent - Raspberry Pi 4B 4GB' },
        ],
    },
    gatus: {
        title: 'Gatus',
        instances: [
            { url: 'https://gatus-1.matejhome.com', title: 'Gatus 1' },
            { url: 'https://gatus-2.matejhome.com', title: 'Gatus 2' },
        ],
    },
    glances: {
        title: 'Glances',
        instances: [
            // { url: 'https://glances-odroid-h3.matejhome.com', title: 'Glances - Odroid H3' },
            { url: 'https://glances-odroid-h4-ultra.matejhome.com', title: 'Glances - Odroid H4 Ultra' },
            { url: 'https://glances-raspberry-pi-4b-2g.matejhome.com', title: 'Glances - Raspberry Pi 4B 2GB' },
            { url: 'https://glances-raspberry-pi-4b-4g.matejhome.com', title: 'Glances - Raspberry Pi 4B 4GB' },
        ],
    },
    gotify: {
        title: 'Gotify',
        instances: [
            { url: 'https://gotify.matejhome.com', title: 'Gotify' },
        ],
    },
    healthchecks: {
        title: 'Healthchecks',
        instances: [
            { url: 'https://healthchecks.matejhome.com', title: 'Healthchecks' },
        ],
    },
    'home-assistant': {
        title: 'Home Assistant',
        instances: [
            { url: 'https://home-assistant.matejhome.com', title: 'Home Assistant' },
        ],
    },
    homepage: {
        title: 'Homepage',
        instances: [
            { url: 'https://homepage.matejhome.com', title: 'Homepage' },
        ],
    },
    jellyfin: {
        title: 'Jellyfin',
        instances: [
            { url: 'https://jellyfin.matejhome.com', title: 'Jellyfin' },
        ],
    },
    minio: {
        title: 'Minio',
        instances: [
            { url: 'https://minio.matejhome.com', title: 'Minio', consoleUrl: 'https://minio-console.matejhome.com' },
        ],
    },
    motioneye: {
        title: 'MotionEye',
        instances: [
            { url: 'https://motioneye-kitchen.matejhome.com', title: 'MotionEye Kitchen' },
        ],
    },
    netalertx: {
        title: 'NetAlertX',
        instances: [
            { url: 'https://netalertx.matejhome.com', title: 'NetAlertX' },
        ],
    },
    ntfy: {
        title: 'Ntfy',
        instances: [
            { url: 'https://ntfy.matejhome.com', title: 'Ntfy' },
        ],
    },
    'node-exporter': {
        title: 'Node Exporter',
        instances: [
            // { url: 'https://node-exporter-odroid-h3.matejhome.com', title: 'Glances - Odroid H3' },
            { url: 'https://node-exporter-odroid-h4-ultra.matejhome.com', title: 'Glances - Odroid H4 Ultra' },
            { url: 'https://node-exporter-raspberry-pi-4b-2g.matejhome.com', title: 'Glances - Raspberry Pi 4B 2GB' },
            { url: 'https://node-exporter-raspberry-pi-4b-4g.matejhome.com', title: 'Glances - Raspberry Pi 4B 4GB' },
        ],
    },
    'omada-controller': {
        title: 'Omada Controller',
        instances: [
            { url: 'https://omada-controller.matejhome.com', title: 'Omada Controller' },
        ],
    },
    openspeedtest: {
        title: 'Openspeedtest',
        forceHttps: false,
        instances: [
            { url: 'https://openspeedtest.matejhome.com', title: 'Openspeedtest' },
        ],
    },
    pihole: {
        title: 'PiHole',
        instances: [
            { url: 'https://pihole-1-primary.matejhome.com', title: 'PiHole 1 Primary' },
            { url: 'https://pihole-1-secondary.matejhome.com', title: 'PiHole 1 Secondary' },
            { url: 'https://pihole-2-primary.matejhome.com', title: 'PiHole 2 Primary' },
            { url: 'https://pihole-2-secondary.matejhome.com', title: 'PiHole 2 Secondary' },
        ],
    },
    prometheus: {
        title: 'Prometheus',
        instances: [
            { url: 'https://prometheus.matejhome.com', title: 'Prometheus' },
        ],
    },
    samba: {
        title: 'SMB',
        instances: [
            { url: 'smb://samba-data.matejhome.com', title: 'SMB (data)' },
            { url: 'smb://samba-snapshots.matejhome.com', title: 'SMB (snapshots)' },
        ],
    },
    smtp4dev: {
        title: 'Smtp4dev',
        instances: [
            { url: 'https://smtp4dev.matejhome.com', title: 'Smtp4dev' },
        ],
    },
    'speedtest-tracker': {
        title: 'Speedtest Tracker',
        instances: [
            { url: 'https://speedtest-tracker.matejhome.com', title: 'Speedtest Tracker' },
        ],
    },
    tvheadend: {
        title: 'Tvheadend',
        instances: [
            { url: 'https://tvheadend.matejhome.com', title: 'Tvheadend' },
        ],
    },
    unbound: {
        title: 'Unbound',
        instances: [
            { url: 'https://unbound-1-default.matejhome.com', title: 'Unbound 1 Default' },
            { url: 'https://unbound-1-open.matejhome.com', title: 'Unbound 1 Open' },
            { url: 'https://unbound-2-default.matejhome.com', title: 'Unbound 2 Default' },
            { url: 'https://unbound-2-open.matejhome.com', title: 'Unbound 2 Open' },
        ]
    },
    'unifi-controller': {
        title: 'UniFi Controller',
        instances: [
            { url: 'https://unifi-controller.matejhome.com', title: 'UniFi Controller' },
        ],
    },
    'uptime-kuma': {
        title: 'Uptime Kuma',
        instances: [
            { url: 'https://uptime-kuma.matejhome.com', title: 'Uptime Kuma' },
        ],
    },
    vaultwarden: {
        title: 'Vaultwarden',
        instances: [
            { url: 'https://vaultwarden.matejhome.com', title: 'Vaultwarden' },
        ],
    },
    // TODO: Enable when Vikunja is deployed
    // vikunja: {
    //     title: 'Vikunja',
    //     instances: [
    //         { url: 'https://vikunja.matejhome.com', title: 'Vikunja' },
    //     ],
    // },
};
