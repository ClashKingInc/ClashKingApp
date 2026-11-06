export function republishManifest(source, { id, createdAt, track, targetVersion, rollbackFrom }) {
  if (!source?.launchAsset || !Array.isArray(source.assets)) {
    throw new Error('Rollback source manifest is missing its launch asset or asset list.');
  }
  return {
    ...source,
    id,
    createdAt,
    metadata: {
      ...(source.metadata ?? {}),
      channel: track,
      version: targetVersion,
      rollbackFrom,
    },
  };
}

export function rollbackDescriptorKey({ track, fromVersion, targetVersion, platform, updateId }) {
  return `rollbacks/${track}/${fromVersion}/${targetVersion}/${platform}-${updateId}.json`;
}
