import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, copyFileSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

// Run the real shell scripts in a disposable clone with a fake Bun command.
// This checks paths and environment loading without opening a window or using a key.
describe.skipIf(process.platform === "win32")("standalone macOS launcher", () => {
  let temp: string;
  let repo: string;
  let bin: string;
  let folder: string;
  let env: Record<string, string | undefined>;

  beforeEach(() => {
    temp = realpathSync(mkdtempSync(join(tmpdir(), "img-gen-launcher-")));
    repo = join(temp, "clones", "img gen");
    bin = join(temp, "bin");
    folder = join(temp, "output images");
    for (const dir of [repo, bin, folder]) mkdirSync(dir, { recursive: true });
    for (const file of ["img-gen", "install.sh"]) copyFileSync(resolve(file), join(repo, file));
    writeFileSync(join(repo, ".env"), "OPENROUTER_API_KEY=repo-test-key\n");
    writeFileSync(join(temp, ".env"), "OPENROUTER_API_KEY=wrong-parent-key\n");
    writeFileSync(join(bin, "bun"), `#!/usr/bin/env bash
printf '%s|%s|%s|%s\\n' "$*" "$PWD" "$FOLDER_PATH" "$OPENROUTER_API_KEY" >> "$CAPTURE"
if [[ "$*" == 'run build:dev' ]]; then mkdir -p build; fi
`);
    chmodSync(join(bin, "bun"), 0o755);
    env = { ...process.env, PATH: `${bin}:${process.env.PATH}`, CAPTURE: join(temp, "capture"), OPENROUTER_API_KEY: "", FOLDER_PATH: "" };
  });

  afterEach(() => rmSync(temp, { recursive: true, force: true }));

  function run(script: string, args: string[]) {
    return Bun.spawnSync(["bash", join(repo, script), ...args], { cwd: temp, env });
  }

  it("loads its own .env when launched through a symlink and builds only once", () => {
    chmodSync(join(repo, "img-gen"), 0o755);
    symlinkSync(join(repo, "img-gen"), join(bin, "img-gen"));
    for (let i = 0; i < 2; i++) {
      expect(Bun.spawnSync([join(bin, "img-gen"), folder], { cwd: temp, env }).exitCode).toBe(0);
    }
    const lines = readFileSync(join(temp, "capture"), "utf8").trim().split("\n");
    expect(lines).toEqual([
      `run build:dev|${repo}|${folder}|repo-test-key`,
      `run dev|${repo}|${folder}|repo-test-key`,
      `run dev|${repo}|${folder}|repo-test-key`,
    ]);
  });

  it("rejects a missing or invalid output folder before running Bun", () => {
    expect(run("img-gen", []).exitCode).toBe(1);
    expect(run("img-gen", [join(temp, "not-a-folder")]).exitCode).toBe(1);
  });

  it("uses an environment key without consulting the old parent .env", () => {
    rmSync(join(repo, ".env"));
    env.OPENROUTER_API_KEY = "environment-test-key";
    expect(run("img-gen", [folder]).exitCode).toBe(0);
    expect(readFileSync(join(temp, "capture"), "utf8")).toContain(`|${folder}|environment-test-key`);
  });

  it("installs an absolute symlink and can be run twice", () => {
    for (let i = 0; i < 2; i++) expect(run("install.sh", [bin]).exitCode).toBe(0);
    expect(Bun.spawnSync([join(bin, "img-gen"), folder], { cwd: temp, env }).exitCode).toBe(0);
  });

  it("optionally installs Bun dependencies from this clone", () => {
    expect(run("install.sh", [bin, "--with-bun-install"]).exitCode).toBe(0);
    expect(readFileSync(join(temp, "capture"), "utf8")).toContain(`install --frozen-lockfile|${repo}|`);
  });
});
