module.exports = {
    platform: 'github',
    onboardingConfig: {
        extends: [
            'config:recommended',
        ],
    },
    repositories: [
        'matejkosiarcik/dotfiles',
        'matejkosiarcik/homelab',
        'matejkosiarcik/azlint',

        // TODO: Re-enable other repositories:
        // 'matejkosiarcik/azminifier',
        // 'matejkosiarcik/website',
    ],
};
