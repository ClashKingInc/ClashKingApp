import {
  Calculator,
  ChartNoAxesCombined,
  ChartPie,
  CircleArrowUp,
  Goal,
  Heart,
  House,
  Images,
  ListChecks,
  Newspaper,
  Search,
  Settings,
  Shield,
  Swords,
  Trophy,
  UserCog,
  UserRound,
  UsersRound,
  type LucideProps,
} from 'lucide-react-native';
import type { ComponentType } from 'react';

import type { AppRouteDefinition, RouteIconName } from './route-manifest';

const iconComponents: Record<RouteIconName, ComponentType<LucideProps>> = {
  house: House,
  'house-filled': House,
  'user-round': UserRound,
  'user-round-filled': UserRound,
  'users-round': UsersRound,
  'users-round-filled': UsersRound,
  swords: Swords,
  search: Search,
  newspaper: Newspaper,
  'chart-no-axes-combined': ChartNoAxesCombined,
  'chart-pie': ChartPie,
  calculator: Calculator,
  heart: Heart,
  'list-checks': ListChecks,
  trophy: Trophy,
  'arrow-up-circle': CircleArrowUp,
  shield: Shield,
  images: Images,
  'user-cog': UserCog,
  settings: Settings,
  goal: Goal,
};

export function RouteIcon({
  route,
  selected = false,
  ...props
}: LucideProps & { route: AppRouteDefinition; selected?: boolean }) {
  const name = selected && route.selectedIcon ? route.selectedIcon : route.icon;
  const Icon = iconComponents[name];
  const filled = selected && name.endsWith('-filled');
  return <Icon fill={filled ? props.color : 'none'} {...props} />;
}
