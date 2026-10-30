import type { StringStorage } from '../../core/storage/storage';

type OnboardingSnapshot = {
  ready: boolean;
  visible: boolean;
  returningUser: boolean;
  userId: string | null;
  revision: number;
  presentation: number;
};

/** Per-account introduction state. It never enables alerts or changes linked accounts. */
class OnboardingService {
  private state: OnboardingSnapshot = {
    ready: false,
    visible: false,
    returningUser: false,
    userId: null,
    revision: 0,
    presentation: 0,
  };
  private storage?: StringStorage;
  private key = '';
  private generation = 0;
  private eligible = false;
  private completed = false;
  private listeners = new Set<() => void>();
  private finishing?: Promise<void>;
  subscribe = (listener: () => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };
  getSnapshot = () => this.state;
  private publish(next: Partial<OnboardingSnapshot>) {
    const opening = next.visible === true && !this.state.visible;
    this.state = {
      ...this.state,
      ...next,
      revision: this.state.revision + 1,
      presentation: this.state.presentation + (opening ? 1 : 0),
    };
    this.listeners.forEach((listener) => listener());
  }
  async bind(storage: StringStorage, userId: string | null) {
    const key = userId ? `onboarding_progress_v1:${userId}` : '';
    if (this.storage === storage && this.key === key) return;
    const generation = ++this.generation;
    this.storage = storage;
    this.key = key;
    this.completed = false;
    this.eligible = false;
    this.finishing = undefined;
    this.publish({ ready: false, visible: false, returningUser: false, userId });
    if (!userId) return;
    let completed = false;
    try {
      const saved = JSON.parse((await storage.getString(key)) ?? 'null') as unknown;
      completed = saved === 'completed' || saved === 'skipped';
      if (!completed) {
        const legacy = JSON.parse(
          (await storage.getString(`tutorial_progress_v1:${userId}`)) ?? '[]',
        ) as unknown;
        // The old Skip action recorded welcome completion too. Never replay the
        // replacement introduction just because its storage format changed.
        completed = Array.isArray(legacy) && legacy.includes('welcome');
      }
    } catch {
      // Corrupt local introduction state must not prevent access to the app.
    }
    if (generation !== this.generation) return;
    this.completed = completed;
    // Hold this value for the session: finishing the introduction must not
    // immediately replace it with a release-announcement modal.
    this.publish({ ready: true, returningUser: completed, visible: !completed && this.eligible });
  }
  setEligible(eligible: boolean) {
    if (eligible === this.eligible) return;
    this.eligible = eligible;
    this.publish({ visible: eligible && this.state.ready && !this.completed });
  }
  finish = (outcome: 'completed' | 'skipped' = 'completed'): Promise<void> => {
    if (this.finishing) return this.finishing;
    const storage = this.storage,
      key = this.key,
      generation = this.generation;
    if (!storage || !key) return Promise.resolve();
    this.finishing = storage
      .setString(key, JSON.stringify(outcome))
      .then(() => {
        if (generation !== this.generation) return;
        this.completed = true;
        this.publish({ visible: false });
      })
      .finally(() => {
        if (generation === this.generation) this.finishing = undefined;
      });
    return this.finishing;
  };
  replay = async () => {
    if (!this.state.ready || !this.key) return;
    this.completed = false;
    this.publish({ returningUser: false, visible: this.eligible });
  };
}

export const onboarding = new OnboardingService();
