export const apps = {
    actualbudget: {
        title: 'ActualBudget',
        instances: [
            { url: 'https://actualbudget.home.matejkosiarcik.com', title: 'ActualBudget (private)' },
        ],
    },
    certbot: {
        title: 'Certbot',
        instances: [
            { url: 'https://certbot.home.matejkosiarcik.com', title: 'Certbot' },
        ],
    },
    changedetection: {
        title: 'Changedetection',
        instances: [
            { url: 'https://changedetection.home.matejkosiarcik.com', title: 'Changedetection' },
        ]
    },
    'docker-proxy': {
        title: 'Docker Proxy',
        instances: [
            { url: 'https://dockerhub-cache-proxy.home.matejkosiarcik.com', title: 'DockerHub Proxy' },
        ],
    },
    dozzle: {
        title: 'Dozzle',
        instances: [
            { url: 'https://dozzle.home.matejkosiarcik.com', title: 'Dozzle server' },
        ],
    },
    'dozzle-agent': {
        title: 'Dozzle Agent',
        instances: [
            { url: 'tcp://dozzle-agent-odroid-h3.home.matejkosiarcik.com', title: 'Dozzle Agent - Odroid H3' },
            { url: 'tcp://dozzle-agent-raspberry-pi-4b-2g.home.matejkosiarcik.com', title: 'Dozzle Agent - Raspberry Pi 4B 2GB' },
            { url: 'tcp://dozzle-agent-raspberry-pi-4b-4g.home.matejkosiarcik.com', title: 'Dozzle Agent - Raspberry Pi 4B 4GB' },
        ],
    },
    gatus: {
        title: 'Gatus',
        instances: [
            { url: 'https://gatus-1.home.matejkosiarcik.com', title: 'Gatus 1' },
            { url: 'https://gatus-2.home.matejkosiarcik.com', title: 'Gatus 2' },
        ],
    },
    glances: {
        title: 'Glances',
        instances: [
            { url: 'https://glances-odroid-h3.home.matejkosiarcik.com', title: 'Glances - Odroid H3' },
            { url: 'https://glances-raspberry-pi-4b-2g.home.matejkosiarcik.com', title: 'Glances - Raspberry Pi 4B 2GB' },
            { url: 'https://glances-raspberry-pi-4b-4g.home.matejkosiarcik.com', title: 'Glances - Raspberry Pi 4B 4GB' },
        ],
    },
    healthchecks: {
        title: 'Healthchecks',
        instances: [
            { url: 'https://healthchecks.home.matejkosiarcik.com', title: 'Healthchecks' },
        ],
    },
    'home-assistant': {
        title: 'Home Assistant',
        instances: [
            { url: 'https://homeassistant.home.matejkosiarcik.com', title: 'Home assistant' },
        ],
    },
    homepage: {
        title: 'Homepage',
        instances: [
            { url: 'https://homepage.home.matejkosiarcik.com', title: 'Homepage' },
        ],
    },
    jellyfin: {
        title: 'Jellyfin',
        instances: [
            { url: 'https://jellyfin.home.matejkosiarcik.com', title: 'Jellyfin' },
        ],
    },
    minio: {
        title: 'Minio',
        instances: [
            { url: 'https://minio.home.matejkosiarcik.com', title: 'Minio', consoleUrl: 'https://minio-console.home.matejkosiarcik.com' },
        ],
    },
    motioneye: {
        title: 'MotionEye',
        instances: [
            { url: 'https://motioneye-stove.home.matejkosiarcik.com', title: 'MotionEye Stove' },
        ],
    },
    netalertx: {
        title: 'NetAlertX',
        instances: [
            { url: 'https://netalertx.home.matejkosiarcik.com', title: 'NetAlertX' },
        ],
    },
    ntfy: {
        title: 'Ntfy',
        forceHttps: false, // TODO: Remove after real Let's Encrypt certificates
        instances: [
            { url: 'https://ntfy.home.matejkosiarcik.com', title: 'Ntfy' },
        ],
    },
    'omada-controller': {
        title: 'Omada Controller',
        instances: [
            { url: 'https://omada-controller.home.matejkosiarcik.com', title: 'Omada Controller' },
        ],
    },
    openspeedtest: {
        title: 'Openspeedtest',
        forceHttps: false,
        instances: [
            { url: 'https://openspeedtest.home.matejkosiarcik.com', title: 'Openspeedtest' },
        ],
    },
    pihole: {
        title: 'PiHole',
        instances: [
            { url: 'https://pihole-1-primary.home.matejkosiarcik.com', title: 'PiHole 1 Primary' },
            { url: 'https://pihole-1-secondary.home.matejkosiarcik.com', title: 'PiHole 1 Secondary' },
            { url: 'https://pihole-2-primary.home.matejkosiarcik.com', title: 'PiHole 2 Primary' },
            { url: 'https://pihole-2-secondary.home.matejkosiarcik.com', title: 'PiHole 2 Secondary' },
        ],
    },
    prometheus: {
        title: 'Prometheus',
        instances: [
            { url: 'https://prometheus.home.matejkosiarcik.com', title: 'Prometheus' },
        ],
    },
    smb: {
        title: 'SMB',
        instances: [
            { url: 'smb://smb-data.home.matejkosiarcik.com', title: 'SMB (data)' },
            { url: 'smb://smb-snapshots.home.matejkosiarcik.com', title: 'SMB (snapshots)' },
        ],
    },
    smtp4dev: {
        title: 'Smtp4dev',
        instances: [
            { url: 'https://smtp4dev.home.matejkosiarcik.com', title: 'Smtp4dev' },
        ],
    },
    'speedtest-tracker': {
        title: 'Speedtest Tracker',
        instances: [
            { url: 'https://speedtest-tracker.home.matejkosiarcik.com', title: 'Speedtest Tracker' },
        ],
    },
    tvheadend: {
        title: 'Tvheadend',
        instances: [
            { url: 'https://tvheadend.home.matejkosiarcik.com', title: 'Tvheadend' },
        ],
    },
    unbound: {
        title: 'Unbound',
        instances: [
            { url: 'https://unbound-1-default.home.matejkosiarcik.com', title: 'Unbound 1 Default' },
            { url: 'https://unbound-1-open.home.matejkosiarcik.com', title: 'Unbound 1 Open' },
            { url: 'https://unbound-2-default.home.matejkosiarcik.com', title: 'Unbound 2 Default' },
            { url: 'https://unbound-2-open.home.matejkosiarcik.com', title: 'Unbound 2 Open' },
        ]
    },
    'unifi-controller': {
        title: 'UniFi Controller',
        instances: [
            { url: 'https://unifi-controller.home.matejkosiarcik.com', title: 'UniFi Controller' },
        ],
    },
    vaultwarden: {
        title: 'Vaultwarden',
        forceHttps: false, // TODO: Remove after real Let's Encrypt certificates
        instances: [
            { url: 'https://vaultwarden.home.matejkosiarcik.com', title: 'Vaultwarden' },
        ],
    },
    // TODO: Enable when Vikunja is deployed
    // vikunja: {
    //     title: 'Vikunja',
    //     instances: [
    //         { url: 'https://vikunja.home.matejkosiarcik.com', title: 'Vikunja' },
    //     ],
    // },
};
