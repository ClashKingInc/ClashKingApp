import { createContext, useContext } from 'react';
import type { AppLinkParams } from './app-link';

export const EMPTY_LINK_PARAMS: AppLinkParams = Object.freeze({});
export const LinkParametersContext = createContext<AppLinkParams>(EMPTY_LINK_PARAMS);
export const useLinkParameters = () => useContext(LinkParametersContext);

export function linkChoice<const T extends string>(
  value: string | undefined,
  choices: readonly T[],
  fallback: T,
): T {
  return choices.includes(value as T) ? (value as T) : fallback;
}
