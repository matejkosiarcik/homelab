export const apps = {
    actualbudget: {
        title: 'ActualBudget',
        instances: [
            { url: 'https://actualbudget.home', title: 'ActualBudget (private)' },
            { url: 'https://actualbudget-public.home', title: 'ActualBudget (public)' },
        ],
    },
    changedetection: {
        title: 'Changedetection',
        instances: [
            { url: 'https://changedetection.home', title: 'Changedetection' },
        ]
    },
    'docker-proxy': {
        title: 'Docker Proxy',
        instances: [
            { url: 'https://dockerhub-proxy.home', title: 'DockerHub Proxy' },
        ],
    },
    dozzle: {
        title: 'Dozzle',
        instances: [
            { url: 'https://dozzle.home', title: 'Dozzle server' },
        ],
    },
    'dozzle-agent': {
        title: 'Dozzle Agent',
        instances: [
            { url: 'tcp://dozzle-agent-odroid-h3.home:7007', title: 'Dozzle Agent - Odroid H3' },
            { url: 'tcp://dozzle-agent-raspberry-pi-3b.home:7007', title: 'Dozzle Agent - Raspberry Pi 3B' },
            { url: 'tcp://dozzle-agent-raspberry-pi-4b-2g.home:7007', title: 'Dozzle Agent - Raspberry Pi 4B 2GB' },
            { url: 'tcp://dozzle-agent-raspberry-pi-4b-4g.home:7007', title: 'Dozzle Agent - Raspberry Pi 4B 4GB' },
        ],
    },
    gatus: {
        title: 'Gatus',
        instances: [
            { url: 'https://gatus.home', title: 'Gatus 1' },
            { url: 'https://gatus-2.home', title: 'Gatus 2' },
        ],
    },
    glances: {
        title: 'Glances',
        instances: [
            { url: 'https://glances-odroid-h3.home', title: 'Glances - Odroid H3' },
            { url: 'https://glances-raspberry-pi-3b.home', title: 'Glances - Raspberry Pi 3B' },
            { url: 'https://glances-raspberry-pi-4b-2g.home', title: 'Glances - Raspberry Pi 4B 2GB' },
            { url: 'https://glances-raspberry-pi-4b-4g.home', title: 'Glances - Raspberry Pi 4B 4GB' },
        ],
    },
    healthchecks: {
        title: 'Healthchecks',
        instances: [
            { url: 'https://healthchecks.home', title: 'Healthchecks' },
        ],
    },
    'home-assistant': {
        title: 'Home Assistant',
        instances: [
            { url: 'https://homeassistant.home', title: 'Home assistant' },
        ],
    },
    homepage: {
        title: 'Homepage',
        instances: [
            { url: 'https://homepage.home', title: 'Homepage' },
        ],
    },
    jellyfin: {
        title: 'Jellyfin',
        instances: [
            { url: 'https://jellyfin.home', title: 'Jellyfin' },
        ],
    },
    minio: {
        title: 'Minio',
        instances: [
            { url: 'https://minio.home', title: 'Minio', consoleUrl: 'https://console.minio.home' },
        ],
    },
    motioneye: {
        title: 'MotionEye',
        instances: [
            { url: 'https://motioneye-stove.home', title: 'MotionEye Stove' },
        ],
    },
    // TODO: Enable when NetAlertX is deployed
    // netalertx: {
    //     title: 'NetAlertX',
    //     instances: [
    //         { url: 'https://netalertx.home', title: 'NetAlertX' },
    //     ],
    // },
    ntfy: {
        title: 'Ntfy',
        forceHttps: false, // TODO: Remove after real Let's Encrypt certificates
        instances: [
            { url: 'https://ntfy.home', title: 'Ntfy' },
        ],
    },
    'omada-controller': {
        title: 'Omada Controller',
        instances: [
            { url: 'https://omada-controller.home', title: 'Omada Controller' },
        ],
    },
    openspeedtest: {
        title: 'Openspeedtest',
        forceHttps: false,
        instances: [
            { url: 'https://openspeedtest.home', title: 'Openspeedtest' },
        ],
    },
    pihole: {
        title: 'PiHole',
        instances: [
            { url: 'https://pihole-1-primary.home', title: 'PiHole Primary 1' },
            { url: 'https://pihole-1-secondary.home', title: 'PiHole Secondary 1' },
            { url: 'https://pihole-2-primary.home', title: 'PiHole Primary 2' },
            { url: 'https://pihole-2-secondary.home', title: 'PiHole Secondary 2' },
        ],
    },
    smtp4dev: {
        title: 'Smtp4dev',
        instances: [
            { url: 'https://smtp4dev.home', title: 'Smtp4dev' },
        ],
    },
    'speedtest-tracker': {
        title: 'Speedtest Tracker',
        instances: [
            { url: 'https://speedtest-tracker.home', title: 'Speedtest Tracker' },
        ],
    },
    tvheadend: {
        title: 'Tvheadend',
        instances: [
            { url: 'https://tvheadend.home', title: 'Tvheadend' },
        ],
    },
    unbound: {
        title: 'Unbound (native)',
        instances: [
            { url: 'unbound-1.home', title: 'Unbound 1' },
            { url: 'unbound-2.home', title: 'Unbound 2' },
        ]
    },
    'unifi-controller': {
        title: 'Unifi Controller',
        instances: [
            { url: 'https://unifi-controller.home', title: 'Unifi Controller' },
        ],
    },
    // TODO: Enable when Vikunja is deployed
    // vikunja: {
    //     title: 'Vikunja',
    //     instances: [
    //         { url: 'https://vikunja.home', title: 'Vikunja' },
    //     ],
    // },
};
