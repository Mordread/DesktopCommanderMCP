import assert from 'node:assert/strict';
import { resolveExecutionProfile } from '../dist/mainrig/execution-profile.js';

function argsFor(shell, env = {}) {
  return resolveExecutionProfile(shell, 'printf test', 'win32', env);
}

assert.equal(argsFor('powershell.exe'), null, 'normal shells must stay on upstream path');
assert.equal(
  resolveExecutionProfile('wsl', 'printf test', 'linux', {}),
  null,
  'WSL aliases are Windows-only'
);

assert.deepEqual(argsFor('wsl'), {
  executable: 'wsl.exe',
  args: ['-d', 'Ubuntu', '--', 'bash', '-lc', 'printf test'],
  useShellOption: false
});

assert.deepEqual(argsFor('wsl:Ubuntu-24.04'), {
  executable: 'wsl.exe',
  args: ['-d', 'Ubuntu-24.04', '--', 'bash', '-lc', 'printf test'],
  useShellOption: false
});
assert.deepEqual(argsFor('wsl', { DC_WSL_DISTRO: 'Debian' }), {
  executable: 'wsl.exe',
  args: ['-d', 'Debian', '--', 'bash', '-lc', 'printf test'],
  useShellOption: false
});

assert.deepEqual(argsFor('  WSL:Debian  '), {
  executable: 'wsl.exe',
  args: ['-d', 'Debian', '--', 'bash', '-lc', 'printf test'],
  useShellOption: false
});

assert.throws(
  () => argsFor('wsl:'),
  /must name a distribution/,
  'an explicit but empty distro must fail closed'
);

console.log('PASS MainRig execution profile preserves stock shells and resolves WSL aliases');
