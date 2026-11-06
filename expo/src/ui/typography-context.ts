import { createContext, useContext } from 'react';

// Tablet text roles are a presentation preference, separate from Dynamic Type.
// The provider leaves phones, Duo, Android and narrow iPad windows unchanged.
export const TabletTypographyContext = createContext(false);
export const useTabletTypography = () => useContext(TabletTypographyContext);
