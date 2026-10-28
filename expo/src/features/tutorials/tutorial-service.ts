import type { StringStorage } from '../../core/storage/storage';
import type { TutorialTextKey } from './tutorial-copy';

export type TutorialId = 'welcome' | 'notifications' | 'clanGuide';
export type TutorialTargetId =
  | 'home-reorder'
  | 'sidebar-open'
  | 'sidebar-links'
  | 'notifications-permission'
  | 'notifications-entities'
  | 'notifications-reminders'
  | 'bookmark'
  | 'clan-pages';
type TutorialAction = 'open-sidebar' | 'close-sidebar' | 'open-notifications' | 'go-home';
export type TutorialStep = {
  title: TutorialTextKey;
  body: TutorialTextKey;
  target?: TutorialTargetId;
  action?: TutorialAction;
  event?: string;
};
export const tutorialSteps: Record<TutorialId, readonly TutorialStep[]> = {
  welcome: [
    { title: 'tutorialWelcomeTitle', body: 'tutorialWelcomeBody' },
    {
      title: 'tutorialReorderTitle',
      body: 'tutorialReorderBody',
      target: 'home-reorder',
      event: 'card-reordered',
    },
    {
      title: 'tutorialSidebarTitle',
      body: 'tutorialSidebarBody',
      target: 'sidebar-open',
      action: 'open-sidebar',
      event: 'sidebar-opened',
    },
    {
      title: 'tutorialExploreTitle',
      body: 'tutorialExploreBody',
      target: 'sidebar-links',
      action: 'open-notifications',
    },
  ],
  notifications: [
    {
      title: 'tutorialPermissionTitle',
      body: 'tutorialPermissionBody',
      target: 'notifications-permission',
    },
    {
      title: 'tutorialEntitiesTitle',
      body: 'tutorialEntitiesBody',
      target: 'notifications-entities',
    },
    {
      title: 'tutorialRemindersTitle',
      body: 'tutorialRemindersBody',
      target: 'notifications-reminders',
    },
  ],
  // Retain the persisted ID for old installs, but retire this tour.
  clanGuide: [],
};
type Target = { reveal: () => void };
type Snapshot = { current: TutorialId | null; step: number; revision: number; ready: boolean; returningUser: boolean; userId: string | null };

/** Local, per-login discovery state. It never modifies accounts or notification preferences. */
class TutorialService {
  private state: Snapshot = { current: null, step: 0, revision: 0, ready: false, returningUser: false, userId: null };
  private listeners = new Set<() => void>();
  private completed = new Set<TutorialId>();
  private pending = new Set<TutorialId>();
  private targets = new Map<TutorialTargetId, Map<symbol, Target>>();
  private actions = new Map<TutorialAction, () => void>();
  private storage?: StringStorage;
  private storageKey = '';
  private generation = 0;
  private writes: Promise<void> = Promise.resolve();
  private homeLoaded = false;
  subscribe = (listener: () => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };
  getSnapshot = () => this.state;
  private publish(next: Partial<Snapshot> = {}) {
    this.state = { ...this.state, ...next, revision: this.state.revision + 1 };
    this.listeners.forEach((listener) => listener());
  }
  async bind(storage: StringStorage, userId: string | null) {
    const key = userId ? `tutorial_progress_v1:${userId}` : '';
    if (this.storageKey === key && this.storage === storage) return;
    const generation = ++this.generation;
    this.storage = storage;
    this.storageKey = key;
    this.completed.clear();
    this.pending.clear();
    this.homeLoaded = false;
    this.publish({ current: null, step: 0, ready: false, returningUser: false, userId });
    if (!key) return;
    let saved: unknown;
    try {
      saved = JSON.parse((await storage.getString(key)) ?? '[]');
    } catch {
      saved = [];
    }
    if (generation !== this.generation) return;
    if (Array.isArray(saved))
      for (const id of saved)
        if (typeof id === 'string' && id in tutorialSteps) this.completed.add(id as TutorialId);
    // Capture eligibility at session start. Completing or skipping onboarding
    // must not immediately replace the tour with a release announcement.
    this.publish({ ready: true, returningUser: this.completed.has('welcome') });
    this.startPending();
  }
  private persist() {
    const storage = this.storage,
      key = this.storageKey,
      value = JSON.stringify([...this.completed]);
    if (!storage || !key) return;
    // Serialize reset/completion writes so a slow previous write cannot undo a reset.
    this.writes = this.writes
      .catch(() => {})
      .then(() => storage.setString(key, value))
      .catch(() => {});
  }
  offer(id: TutorialId) {
    if (id === 'clanGuide') return;
    if (!this.storageKey || this.completed.has(id) || this.state.current === id) return;
    this.pending.add(id);
    if (this.state.ready) this.startPending();
  }
  visitHome(loaded = false) {
    if (loaded) this.homeLoaded = true;
    if (this.homeLoaded) this.offer('welcome');
  }
  private startPending() {
    if (this.state.current || !this.state.ready) return;
    const id = [...this.pending].find(
      (candidate) =>
        !this.completed.has(candidate) &&
        (candidate === 'welcome' || this.completed.has('welcome')),
    );
    if (!id) return;
    this.pending.delete(id);
    this.publish({ current: id, step: 0 });
  }
  next = () => {
    const id = this.state.current;
    if (!id) return;
    const step = tutorialSteps[id][this.state.step];
    const action = step?.action ? this.actions.get(step.action) : undefined;
    if (step?.action === 'open-sidebar' && action) {
      action();
      return;
    }
    if (this.state.step + 1 < tutorialSteps[id].length) this.publish({ step: this.state.step + 1 });
    else this.finish();
    action?.();
  };
  dismiss = () => {
    // Welcome and Notifications form one onboarding flow. Skip must persist
    // for both, including a Notifications screen opened manually later.
    if (this.state.current === 'welcome') {
      this.completed.add('notifications');
      this.pending.delete('notifications');
    }
    this.finish();
  };
  finish = () => {
    const finished = this.state.current;
    if (finished) {
      this.completed.add(finished);
      this.pending.delete(finished);
    }
    this.persist();
    this.publish({ current: null, step: 0 });
    if (finished === 'notifications') {
      this.actions.get('close-sidebar')?.();
      this.actions.get('go-home')?.();
    }
    this.startPending();
  };
  event(name: string) {
    const id = this.state.current;
    if (id && tutorialSteps[id][this.state.step]?.event === name) {
      if (this.state.step + 1 < tutorialSteps[id].length)
        this.publish({ step: this.state.step + 1 });
      else this.finish();
    }
  }
  reset = async () => {
    this.completed.clear();
    this.pending.clear();
    this.publish({ current: null, step: 0, returningUser: false });
    this.persist();
    await this.writes;
  };
  registerTarget(id: TutorialTargetId, target: Target) {
    const token = Symbol(id);
    const group = this.targets.get(id) ?? new Map<symbol, Target>();
    group.set(token, target);
    this.targets.set(id, group);
    this.publish();
    return () => {
      group.delete(token);
      this.publish();
    };
  }
  target(id: TutorialTargetId) {
    return [...(this.targets.get(id)?.values() ?? [])].at(-1);
  }
  registerAction(id: TutorialAction, action: () => void) {
    this.actions.set(id, action);
    return () => {
      if (this.actions.get(id) === action) this.actions.delete(id);
    };
  }
}
export const tutorials = new TutorialService();
