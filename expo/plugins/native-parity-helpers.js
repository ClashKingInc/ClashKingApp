'use strict';

const fs = require('node:fs');
const path = require('node:path');

function assertExact(label, actual, expected) {
  if (actual != null && actual !== expected) {
    throw new Error(`${label} must be ${expected}; received ${actual}`);
  }
  return expected;
}

function appendUnique(values, additions) {
  return [...new Set([...(values || []), ...additions])];
}

function requirePath(projectRoot, relativePath, label = relativePath) {
  const resolved = path.resolve(projectRoot, relativePath);
  if (!fs.existsSync(resolved)) {
    throw new Error(`Missing ${label}: ${resolved}`);
  }
  return resolved;
}

function validateRelativeTarget(relativePath) {
  if (!relativePath || path.isAbsolute(relativePath)) {
    throw new Error(`Copy target must be a non-empty relative path: ${relativePath}`);
  }
  const normalized = path.normalize(relativePath);
  if (normalized === '..' || normalized.startsWith(`..${path.sep}`)) {
    throw new Error(`Copy target escapes the generated native project: ${relativePath}`);
  }
  return normalized;
}

function copyFileIfChanged(source, destination) {
  const sourceBuffer = fs.readFileSync(source);
  if (fs.existsSync(destination) && fs.readFileSync(destination).equals(sourceBuffer)) {
    return false;
  }
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.writeFileSync(destination, sourceBuffer);
  return true;
}

function copyTreeIfChanged(sourceRoot, destinationRoot) {
  if (!fs.statSync(sourceRoot).isDirectory()) {
    throw new Error(`Copy source is not a directory: ${sourceRoot}`);
  }
  let changed = 0;
  for (const entry of fs.readdirSync(sourceRoot, { withFileTypes: true })) {
    const source = path.join(sourceRoot, entry.name);
    const destination = path.join(destinationRoot, entry.name);
    if (entry.isDirectory()) {
      changed += copyTreeIfChanged(source, destination);
    } else if (entry.isFile()) {
      changed += copyFileIfChanged(source, destination) ? 1 : 0;
    } else {
      throw new Error(`Unsupported native source entry: ${source}`);
    }
  }
  return changed;
}

function copyRelativeFilesIfChanged(sourceRoot, destinationRoot, relativePaths) {
  let changed = 0;
  for (const relativePath of relativePaths) {
    const safePath = validateRelativeTarget(relativePath);
    const source = requirePath(sourceRoot, safePath, `native parity input ${safePath}`);
    if (!fs.statSync(source).isFile()) {
      throw new Error(`Declared native parity input is not a file: ${source}`);
    }
    changed += copyFileIfChanged(source, path.join(destinationRoot, safePath)) ? 1 : 0;
  }
  return changed;
}

function validateRequiredFiles(sourceRoot, requiredFiles) {
  for (const relativePath of requiredFiles) {
    requirePath(sourceRoot, relativePath, `native parity input ${relativePath}`);
  }
}

module.exports = {
  appendUnique,
  assertExact,
  copyFileIfChanged,
  copyRelativeFilesIfChanged,
  copyTreeIfChanged,
  requirePath,
  validateRelativeTarget,
  validateRequiredFiles,
};
