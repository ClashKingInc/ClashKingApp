import { createContext, useContext } from 'react';

// NativeTabs includes the system bar in each route's safe-area insets.
// Consumers must not add the retained Android pager's fixed bar clearance.
export const NativePrimaryNavigation = createContext(false);
export const useNativePrimaryNavigation = () => useContext(NativePrimaryNavigation);
