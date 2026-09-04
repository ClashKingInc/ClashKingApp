import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

import { parse } from '@babel/parser';

const expoRoot = path.resolve(import.meta.dirname, '..');
const sourceRoot = path.join(expoRoot, 'src');
const contractsRoot = path.join(expoRoot, 'node_modules/@clashking/api-contracts');
const contractsPackage = JSON.parse(
  fs.readFileSync(path.join(contractsRoot, 'package.json'), 'utf8'),
);
const expoExport = contractsPackage.exports?.['./expo'];
const failures = [];

if (expoExport?.types !== './dist/expo.d.ts' || expoExport?.import !== './dist/expo.js') {
  failures.push('the contracts package must expose ./expo with dist/expo types and import targets');
}

function collectSourceFiles(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const absolutePath = path.join(directory, entry.name);
    if (entry.isDirectory()) return collectSourceFiles(absolutePath);
    return /\.(?:ts|tsx)$/u.test(entry.name) ? [absolutePath] : [];
  });
}

const appSourceFiles = collectSourceFiles(sourceRoot);
for (const absolutePath of appSourceFiles) {
  const source = parse(fs.readFileSync(absolutePath, 'utf8'), {
    sourceType: 'module',
    plugins: ['typescript', ...(absolutePath.endsWith('.tsx') ? ['jsx'] : [])],
  });
  for (const statement of source.program.body) {
    if ('source' in statement && statement.source?.value === '@clashking/api-contracts') {
      failures.push(
        `${path.relative(expoRoot, absolutePath)} imports the root contracts barrel instead of /expo`,
      );
    }
  }
}

const entrypoint = path.join(contractsRoot, 'dist/expo.js');
const contractModules = new Set();
const allowedExternalImports = new Set(['effect']);
const serverOnlyModule = /^(?:admin|bot(?:-|\.)|dashboard|persistent-runtime|current-war-summary)/u;

function inspectContractModule(absolutePath) {
  if (contractModules.has(absolutePath)) return;
  contractModules.add(absolutePath);
  if (!fs.existsSync(absolutePath)) {
    failures.push(`missing contracts module ${path.relative(contractsRoot, absolutePath)}`);
    return;
  }

  const moduleName = path.basename(absolutePath);
  if (serverOnlyModule.test(moduleName)) {
    failures.push(`the Expo contracts graph reaches server-only module ${moduleName}`);
  }

  const source = parse(fs.readFileSync(absolutePath, 'utf8'), { sourceType: 'module' });
  for (const statement of source.program.body) {
    if (!('source' in statement) || statement.source === null || statement.source === undefined) {
      continue;
    }
    const specifier = statement.source.value;
    if (specifier.startsWith('.')) {
      const dependency = path.resolve(path.dirname(absolutePath), specifier);
      if (!dependency.startsWith(`${path.join(contractsRoot, 'dist')}${path.sep}`)) {
        failures.push(`${moduleName} reaches a module outside the contracts dist directory`);
      } else {
        inspectContractModule(dependency);
      }
    } else if (!allowedExternalImports.has(specifier)) {
      failures.push(`${moduleName} imports unexpected runtime dependency ${specifier}`);
    }
  }
}

inspectContractModule(entrypoint);

if (failures.length > 0) {
  console.error(`Expo API package boundary check failed:\n${failures.join('\n')}`);
  process.exit(1);
}

console.log(
  `Expo API package boundary check passed (${appSourceFiles.length} app files, ${contractModules.size} contract modules).`,
);
