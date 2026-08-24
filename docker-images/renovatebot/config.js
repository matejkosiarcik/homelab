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

        // TODO: Re-enable other repositories:
        // 'matejkosiarcik/azlint',
        // 'matejkosiarcik/azminifier',
        // 'matejkosiarcik/website',
    ],
};
