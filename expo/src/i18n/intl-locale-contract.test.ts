import fs from 'node:fs';
import path from 'node:path';
import ts from 'typescript';

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
  const sourceFile = ts.createSourceFile(
    filePath,
    fs.readFileSync(filePath, 'utf8'),
    ts.ScriptTarget.Latest,
    true,
    filePath.endsWith('.tsx') ? ts.ScriptKind.TSX : ts.ScriptKind.TS,
  );
  const lines = new Set<number>();
  const record = (node: ts.Node) => {
    lines.add(sourceFile.getLineAndCharacterOfPosition(node.getStart(sourceFile)).line + 1);
  };
  const visit = (node: ts.Node) => {
    if (ts.isCallExpression(node) && isRawLocaleReplacement(node)) record(node);
    if ((ts.isCallExpression(node) || ts.isNewExpression(node)) && isLocaleConsumer(node)) {
      const argument = node.arguments?.[0];
      if (argument && isUnsafeLocaleArgument(argument)) record(argument);
    }
    ts.forEachChild(node, visit);
  };
  visit(sourceFile);
  return [...lines]
    .sort((left, right) => left - right)
    .map((line) => `${path.relative(process.cwd(), filePath)}:${line}`);
}

function isLocaleConsumer(node: ts.CallExpression | ts.NewExpression): boolean {
  const expression = node.expression;
  if (!ts.isPropertyAccessExpression(expression)) return false;
  if (['toLocaleString', 'toLocaleDateString', 'toLocaleTimeString'].includes(expression.name.text))
    return true;
  return (
    ts.isIdentifier(expression.expression) &&
    expression.expression.text === 'Intl' &&
    [
      'NumberFormat',
      'DateTimeFormat',
      'RelativeTimeFormat',
      'PluralRules',
      'ListFormat',
      'DisplayNames',
    ].includes(expression.name.text)
  );
}

function isRawLocaleReplacement(node: ts.CallExpression): boolean {
  return (
    ts.isPropertyAccessExpression(node.expression) &&
    ['replace', 'replaceAll'].includes(node.expression.name.text) &&
    isRawLocaleReference(node.expression.expression)
  );
}

function isUnsafeLocaleArgument(node: ts.Expression): boolean {
  if (ts.isParenthesizedExpression(node) || ts.isAsExpression(node) || ts.isNonNullExpression(node))
    return isUnsafeLocaleArgument(node.expression);
  if (ts.isConditionalExpression(node))
    return isUnsafeLocaleArgument(node.whenTrue) || isUnsafeLocaleArgument(node.whenFalse);
  if (ts.isBinaryExpression(node))
    return isUnsafeLocaleArgument(node.left) || isUnsafeLocaleArgument(node.right);
  if (ts.isCallExpression(node)) {
    if (ts.isIdentifier(node.expression) && node.expression.text === 'toIntlLocale') return false;
    return isRawLocaleReplacement(node);
  }
  return isRawLocaleReference(node);
}

function isRawLocaleReference(node: ts.Expression): boolean {
  if (ts.isIdentifier(node)) return node.text === 'locale';
  return ts.isPropertyAccessExpression(node) && node.name.text === 'locale';
}
