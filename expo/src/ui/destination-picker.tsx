import { type ReactNode } from 'react';

import { SelectionPicker } from './selection-picker';

export type DestinationPickerOption = {
  key: string;
  label: string;
  icon?: ReactNode;
};

export function DestinationPicker({
  options,
  selectedKey,
  onSelect,
  accessibilityLabel,
  onOpen,
  externallyManaged = false,
  showPositionHint = false,
}: {
  options: readonly DestinationPickerOption[];
  selectedKey: string;
  onSelect: (key: string) => void;
  accessibilityLabel?: string;
  onOpen?: () => void;
  externallyManaged?: boolean;
  showPositionHint?: boolean;
}) {
  const title =
    accessibilityLabel ?? options.find((option) => option.key === selectedKey)?.label ?? '';
  const selectedIndex = options.findIndex((option) => option.key === selectedKey);
  return (
    <SelectionPicker
      accessibilityLabel={accessibilityLabel}
      externallyManaged={externallyManaged}
      onOpen={onOpen}
      onSelect={onSelect}
      options={options}
      positionLabel={
        showPositionHint && selectedIndex >= 0
          ? `${selectedIndex + 1}/${options.length}`
          : undefined
      }
      selectedKey={selectedKey}
      title={title}
    />
  );
}
