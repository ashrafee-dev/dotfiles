const fs = require('node:fs');
const path = require('node:path');
const home = process.env.DOTFILES_DEBUG_HOME;
const { chromium } = require(path.join(home, 'node_modules/playwright'));
(async () => {
  // Fail provisioning if the downloaded browser cannot actually start.
  const browser = await chromium.launch({ headless: true });
  await browser.close();
  fs.writeFileSync(path.join(home, 'environment.json'), JSON.stringify({
    java_home: process.env.JAVA_HOME,
    llvm_bin: process.env.DOTFILES_LLVM_BIN,
    chromium: chromium.executablePath(),
  }, null, 2));
})().catch(error => {
  console.error('FAILED: Browser setup:', error.message);
  console.error('On Linux, install browser system libraries with: npx playwright install-deps chromium');
  process.exitCode = 1;
});
