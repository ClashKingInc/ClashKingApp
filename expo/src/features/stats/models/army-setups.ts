import {
  ArmySetupsEndpoint,
  ArmySetupTimelineEndpoint,
  type EndpointRequest,
  type EndpointResponse,
} from '@clashking/api-contracts/expo';

import { StatsDateFilter } from './stats-models';

export type StatsArmySetupQuery = EndpointRequest<typeof ArmySetupsEndpoint>['query'];
export type StatsArmySetupResponse = EndpointResponse<typeof ArmySetupsEndpoint>;
export type StatsArmySetupItem = StatsArmySetupResponse['items'][number];
export type StatsArmySetupTimelineResponse = EndpointResponse<typeof ArmySetupTimelineEndpoint>;

export function armySetupQuery(
  dates: StatsDateFilter,
  rankLimit?: 200 | 1000,
  groupKey?: string,
  variantKey?: string,
  sort: 'usage' | 'tripleRate' = 'usage',
): StatsArmySetupQuery {
  return {
    'time[after]': StatsDateFilter.formatDate(dates.start),
    'time[before]': StatsDateFilter.formatDate(dates.end),
    leagueTierId: 105000036,
    ...(rankLimit == null ? {} : { rankLimit }),
    ...(groupKey == null ? {} : { groupKey }),
    ...(variantKey == null ? {} : { variantKey }),
    sort,
    limit: 100,
  };
}
