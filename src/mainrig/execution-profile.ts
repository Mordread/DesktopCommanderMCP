export interface ExecutionProfile {
  executable: string;
  args: string[];
  useShellOption: string | boolean;
}

const WSL_PREFIX = /^wsl(?::(.*))?$/i;

function validDistroName(value: string): boolean {
  return value.length > 0 && !/[\0\r\n]/.test(value);
}

/**
 * Resolve opt-in MainRig shell aliases without changing normal upstream shells.
 * Returns null when the shell should follow Desktop Commander's stock path.
 */
export function resolveExecutionProfile(
  shellPath: string,
  command: string,
  platform: NodeJS.Platform = process.platform,
  env: NodeJS.ProcessEnv = process.env
): ExecutionProfile | null {
  if (platform !== 'win32') return null;

  const match = WSL_PREFIX.exec(shellPath.trim());
  if (!match) return null;

  const explicitDistro = match[1]?.trim();
  if (match[1] !== undefined && !explicitDistro) {
    throw new Error('WSL shell alias must name a distribution after the colon');
  }
  const configuredDistro = env.DC_WSL_DISTRO?.trim();
  const distro = explicitDistro || configuredDistro || 'Ubuntu';

  if (!validDistroName(distro)) {
    throw new Error('Invalid WSL distribution name');
  }

  return {
    executable: 'wsl.exe',
    args: ['-d', distro, '--', 'bash', '-lc', command],
    useShellOption: false
  };
}
