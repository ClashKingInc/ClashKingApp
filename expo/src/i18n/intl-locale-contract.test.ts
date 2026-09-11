import fs from 'node:fs';
import path from 'node:path';
import { parse } from '@babel/parser';
import traverse from '@babel/traverse';
import * as t from '@babel/types';

describe('app-wide Intl locale contract', () => {
  it('normalizes ARB locale tags before passing them to Intl', () => {
    const sourceRoot = path.resolve(__dirname, '..');
    const helperFile = path.join(sourceRoot, 'i18n', 'i18n.tsx');
    const violations = findProductionTypeScript(sourceRoot).flatMap((filePath) =>
      filePath === helperFile ? [] : findUnsafeLocaleUsage(filePath),
    );

    expect(violations).toEqual([]);
  });
});

function findProductionTypeScript(root: string): string[] {
  return fs.readdirSync(root, { withFileTypes: true }).flatMap((entry) => {
    const entryPath = path.join(root, entry.name);
    if (entry.isDirectory()) return findProductionTypeScript(entryPath);
    if (!entry.isFile() || !/\.tsx?$/.test(entry.name) || /\.test\.tsx?$/.test(entry.name))
      return [];
    return [entryPath];
  });
}

function findUnsafeLocaleUsage(filePath: string): string[] {
  const sourceFile = parse(fs.readFileSync(filePath, 'utf8'), {
    sourceType: 'module',
    plugins: ['typescript', ...(filePath.endsWith('.tsx') ? (['jsx'] as const) : [])],
  });
  const lines = new Set<number>();
  const record = (node: t.Node) => lines.add(node.loc?.start.line ?? 0);
  const inspect = (node: t.CallExpression | t.NewExpression) => {
    if (t.isCallExpression(node) && isRawLocaleReplacement(node)) record(node);
    if (!isLocaleConsumer(node)) return;
    const argument = node.arguments[0];
    if (argument !== undefined && t.isExpression(argument) && isUnsafeLocaleArgument(argument)) {
      record(argument);
    }
  };
  traverse(sourceFile, {
    CallExpression: ({ node }) => inspect(node),
    NewExpression: ({ node }) => inspect(node),
  });
  return [...lines]
    .filter((line) => line > 0)
    .sort((left, right) => left - right)
    .map((line) => `${path.relative(process.cwd(), filePath)}:${line}`);
}

function isLocaleConsumer(node: t.CallExpression | t.NewExpression): boolean {
  const expression = node.callee;
  if (!t.isMemberExpression(expression) || expression.computed) return false;
  if (!t.isIdentifier(expression.property)) return false;
  if (
    ['toLocaleString', 'toLocaleDateString', 'toLocaleTimeString'].includes(
      expression.property.name,
    )
  )
    return true;
  return (
    t.isIdentifier(expression.object, { name: 'Intl' }) &&
    [
      'NumberFormat',
      'DateTimeFormat',
      'RelativeTimeFormat',
      'PluralRules',
      'ListFormat',
      'DisplayNames',
    ].includes(expression.property.name)
  );
}

function isRawLocaleReplacement(node: t.CallExpression): boolean {
  return (
    t.isMemberExpression(node.callee) &&
    !node.callee.computed &&
    t.isIdentifier(node.callee.property) &&
    ['replace', 'replaceAll'].includes(node.callee.property.name) &&
    t.isExpression(node.callee.object) &&
    isRawLocaleReference(node.callee.object)
  );
}

function isUnsafeLocaleArgument(node: t.Expression): boolean {
  if (
    t.isParenthesizedExpression(node) ||
    t.isTSAsExpression(node) ||
    t.isTSNonNullExpression(node)
  )
    return isUnsafeLocaleArgument(node.expression as t.Expression);
  if (t.isConditionalExpression(node))
    return isUnsafeLocaleArgument(node.consequent) || isUnsafeLocaleArgument(node.alternate);
  if (t.isBinaryExpression(node) || t.isLogicalExpression(node))
    return (
      (t.isExpression(node.left) && isUnsafeLocaleArgument(node.left)) ||
      isUnsafeLocaleArgument(node.right)
    );
  if (t.isCallExpression(node)) {
    if (t.isIdentifier(node.callee, { name: 'toIntlLocale' })) return false;
    return isRawLocaleReplacement(node);
  }
  return isRawLocaleReference(node);
}

function isRawLocaleReference(node: t.Expression): boolean {
  if (t.isIdentifier(node)) return node.name === 'locale';
  return (
    t.isMemberExpression(node) &&
    !node.computed &&
    t.isIdentifier(node.property, { name: 'locale' })
  );
}
