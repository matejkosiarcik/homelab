const productionConfig = require('/usr/src/app/config.js');
module.exports = {
  ...productionConfig,
  autodiscover: false,
  platform: 'local',
  repositories: [],
};
