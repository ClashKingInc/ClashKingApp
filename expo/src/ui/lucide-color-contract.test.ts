import fs from 'node:fs';
import path from 'node:path';
import ts from 'typescript';

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
  const sourceFile = ts.createSourceFile(
    filePath,
    source,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TSX,
  );
  const iconNames = new Set<string>();
  for (const statement of sourceFile.statements) {
    if (
      !ts.isImportDeclaration(statement) ||
      statement.moduleSpecifier.getText(sourceFile).slice(1, -1) !== 'lucide-react-native'
    )
      continue;
    const bindings = statement.importClause?.namedBindings;
    if (!bindings || !ts.isNamedImports(bindings)) continue;
    bindings.elements.forEach((element) => iconNames.add(element.name.text));
  }

  const violations: string[] = [];
  const visit = (node: ts.Node) => {
    if (
      (ts.isJsxSelfClosingElement(node) || ts.isJsxOpeningElement(node)) &&
      ts.isIdentifier(node.tagName) &&
      iconNames.has(node.tagName.text)
    ) {
      const attributes = node.attributes.properties;
      const hasColour = attributes.some(
        (attribute) =>
          ts.isJsxAttribute(attribute) && attribute.name.getText(sourceFile) === 'color',
      );
      const delegatesProps = attributes.some(ts.isJsxSpreadAttribute);
      if (!hasColour && !delegatesProps) {
        const { line } = sourceFile.getLineAndCharacterOfPosition(node.getStart(sourceFile));
        violations.push(
          `${path.relative(process.cwd(), filePath)}:${line + 1} ${node.tagName.text}`,
        );
      }
    }
    ts.forEachChild(node, visit);
  };
  visit(sourceFile);
  return violations;
}
