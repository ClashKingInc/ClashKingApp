import { parse } from '@babel/parser';

export function moduleSpecifiers(source, plugins = []) {
  const ast = parse(source, { sourceType: 'module', plugins, createImportExpressions: true });
  const specifiers = new Set();
  const add = (node) => {
    if (node?.type === 'StringLiteral') specifiers.add(node.value);
  };
  function visit(node) {
    if (node === null || typeof node !== 'object') return;
    if (Array.isArray(node)) {
      for (const child of node) visit(child);
      return;
    }
    if (
      [
        'ImportDeclaration',
        'ExportNamedDeclaration',
        'ExportAllDeclaration',
        'ImportExpression',
      ].includes(node.type)
    ) {
      add(node.source);
    } else if (node.type === 'TSImportType') {
      add(node.argument);
    } else if (
      node.type === 'CallExpression' &&
      (node.callee?.type === 'Import' ||
        (node.callee?.type === 'Identifier' && node.callee.name === 'require'))
    ) {
      add(node.arguments[0]);
    }
    for (const child of Object.values(node)) visit(child);
  }
  visit(ast);
  return [...specifiers];
}

export function disallowedAppContractImports(source, plugins = ['typescript']) {
  return moduleSpecifiers(source, plugins).filter(
    (specifier) =>
      (specifier === '@clashking/api-contracts' ||
        specifier.startsWith('@clashking/api-contracts/')) &&
      specifier !== '@clashking/api-contracts/expo',
  );
}
