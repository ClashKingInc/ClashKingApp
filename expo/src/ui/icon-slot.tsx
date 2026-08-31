import { cloneElement, isValidElement, type ReactElement, type ReactNode } from 'react';

type TintableIconProps = {
  color?: string;
};

/**
 * Applies the current surface colour to an icon-slot element whose caller
 * omitted it. Callers only pass vector artwork through this helper; game
 * images remain regular image children and keep their original palette.
 */
export function tintIcon(icon: ReactNode, color: string): ReactNode {
  if (!isValidElement(icon)) return icon;
  const element = icon as ReactElement<TintableIconProps>;
  const props = element.props;
  if (props.color) return icon;
  return cloneElement(element, { color });
}
