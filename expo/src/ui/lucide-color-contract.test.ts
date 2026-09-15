import fs from 'node:fs';
import path from 'node:path';
import { parse } from '@babel/parser';
import traverse from '@babel/traverse';
import * as t from '@babel/types';

const productionRoots = ['app', 'core', 'features', 'navigation', 'shell', 'ui'];

describe('app-wide Lucide colour contract', () => {
  it('never leaves a production vector icon on Lucide’s black default', () => {
    const sourceRoot = path.resolve(__dirname, '..');
    const violations = productionRoots.flatMap((relativeRoot) =>
      findTsxFiles(path.join(sourceRoot, relativeRoot)).flatMap(findUntintedLucideElements),
    );

    expect(violations).toEqual([]);
  });
});

function findTsxFiles(root: string): string[] {
  return fs.readdirSync(root, { withFileTypes: true }).flatMap((entry) => {
    const entryPath = path.join(root, entry.name);
    if (entry.isDirectory()) return findTsxFiles(entryPath);
    return entry.isFile() && entry.name.endsWith('.tsx') && !entry.name.endsWith('.test.tsx')
      ? [entryPath]
      : [];
  });
}

function findUntintedLucideElements(filePath: string): string[] {
  const source = fs.readFileSync(filePath, 'utf8');
  const sourceFile = parse(source, { sourceType: 'module', plugins: ['typescript', 'jsx'] });
  const iconNames = new Set<string>();
  for (const statement of sourceFile.program.body) {
    if (!t.isImportDeclaration(statement) || statement.source.value !== 'lucide-react-native')
      continue;
    statement.specifiers.forEach((specifier) => {
      if (t.isImportSpecifier(specifier)) iconNames.add(specifier.local.name);
    });
  }

  const violations: string[] = [];
  traverse(sourceFile, {
    JSXOpeningElement: ({ node }) => {
      if (t.isJSXIdentifier(node.name) && iconNames.has(node.name.name)) {
        const attributes = node.attributes;
        const hasColour = attributes.some(
          (attribute) =>
            t.isJSXAttribute(attribute) && t.isJSXIdentifier(attribute.name, { name: 'color' }),
        );
        const delegatesProps = attributes.some((attribute) => t.isJSXSpreadAttribute(attribute));
        if (!hasColour && !delegatesProps) {
          violations.push(
            `${path.relative(process.cwd(), filePath)}:${node.loc?.start.line ?? 0} ${node.name.name}`,
          );
        }
      }
    },
  });
  return violations;
}
