#!/usr/bin/env node

const testEnabled = false;
if (!testEnabled) {
  return;
}

// OpenZeppelin script: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/e5fbbda9bac49039847a7ed20c1d966766ecc64a/scripts/coverage.js

const { execSync } = require('child_process');
const { runCoverage } = require('@openzeppelin/test-environment');

async function main () {
  await runCoverage(
    ['mocks'],
    'npm run compile',
    './node_modules/.bin/mocha --exit --timeout 10000 --recursive'.split(' '),
  );

  if (process.env.CI) {
    execSync('curl -s https://codecov.io/bash | bash -s -- -C "$CIRCLE_SHA1"', { stdio: 'inherit' });
  }
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});